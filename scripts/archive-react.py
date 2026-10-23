"""Archive a React build, keeping only the three newest S3 artifact ZIPs."""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile
import zipfile


def aws(*args):
    result = subprocess.run(['aws', *args, '--region', 'us-east-1'],
                            check=True, capture_output=True, text=True)
    return json.loads(result.stdout) if result.stdout.strip() else {}


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('bucket')
parser.add_argument('--run')
options = parser.parse_args()
prefix = 'artifacts/github-actions/'
if options.run:
    if not options.run.isdigit():
        parser.error('--run must be a numeric GitHub run ID')
    with tempfile.TemporaryDirectory() as temporary:
        archive = Path(temporary) / f'react-build-{options.run}.zip'
        with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as output:
            for path in sorted(Path('react-app/dist').rglob('*')):
                if path.is_file():
                    output.write(path, path.relative_to('react-app/dist'))
        if not zipfile.ZipFile(archive).namelist():
            raise RuntimeError('Build is empty; refusing upload and cleanup')
        aws('s3api', 'put-object', '--bucket', options.bucket, '--key',
            f'{prefix}{options.run}/{archive.name}', '--body', str(archive),
            '--server-side-encryption', 'AES256', '--content-type', 'application/zip')
objects = aws('s3api', 'list-objects-v2', '--bucket', options.bucket,
              '--prefix', prefix).get('Contents', [])
archives = sorted((item for item in objects if item['Key'].endswith('.zip')),
                  key=lambda item: (item['LastModified'], item['Key']), reverse=True)
for item in archives[3:]:
    aws('s3api', 'delete-object', '--bucket', options.bucket, '--key', item['Key'])
    print('Deleted old artifact:', item['Key'])
print(f'Retained {min(len(archives), 3)} artifact ZIPs (limit: 3).')
