"""Build a pinned PowerShell runtime layer; no AWS credentials are packaged."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import tarfile
import urllib.request
import zipfile

root = Path(__file__).resolve().parent.parent
config = json.loads((root / 'lambda-runtime/dependencies.json').read_text())
build = root / 'build/lambda'
build.mkdir(parents=True, exist_ok=True)
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--sdk-only', action='store_true')
args = parser.parse_args()


def download(url):
    request = urllib.request.Request(url, headers={'User-Agent': 'Motohaus-build'})
    with urllib.request.urlopen(request, timeout=120) as response:
        return response.read()


sdk = build / 'sdk'
sdk.mkdir(exist_ok=True)
for package, version in config['packages'].items():
    name = package.lower()
    data = download(f'https://api.nuget.org/v3-flatcontainer/{name}/{version}/{name}.{version}.nupkg')
    archive = zipfile.ZipFile(io.BytesIO(data))
    (sdk / f'{package}.dll').write_bytes(archive.read(f'lib/net8.0/{package}.dll'))
if not args.sdk_only:
    version = config['powershell']
    runtime = build / f'powershell-{version}.tar.gz'
    if not runtime.exists():
        runtime.write_bytes(download('https://github.com/PowerShell/PowerShell/releases/'
                                    f'download/v{version}/powershell-{version}-linux-x64.tar.gz'))
    if hashlib.sha256(runtime.read_bytes()).hexdigest() != config['powershell_sha256']:
        raise RuntimeError('PowerShell archive checksum mismatch')
    with zipfile.ZipFile(build / 'runtime.zip', 'w', zipfile.ZIP_DEFLATED) as output:
        with tarfile.open(runtime) as archive:
            for member in archive:
                if member.isfile():
                    relative = Path(member.name)
                    if relative.is_absolute() or '..' in relative.parts:
                        raise ValueError('Unsafe runtime path')
                    info = zipfile.ZipInfo('powershell/' + relative.as_posix())
                    info.create_system = 3
                    info.external_attr = (0o100755 if member.mode & 0o111 else 0o100644) << 16
                    info.compress_type = zipfile.ZIP_DEFLATED
                    output.writestr(info, archive.extractfile(member).read())
        for path in sorted(sdk.glob('*.dll')):
            info = zipfile.ZipInfo('sdk/' + path.name)
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            output.writestr(info, path.read_bytes())
    print('Runtime layer built:', build / 'runtime.zip')
print('AWS SDK assemblies:', sdk)
