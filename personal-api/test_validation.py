import json
import unittest
from test_support import validate, administrator, payload, event, claims

class ValidationTests(unittest.TestCase):
    def test_valid_contact(self):
        self.assertEqual(validate(event())["name"], "Example Rider")

    def test_invalid_inputs(self):
        for values in [{"email":"bad"},{"phone":"abc"},{"consent":False},
                       {"name":"x"*121},{"requestId":"wrong"},{"interest":"unknown"},
                       {"name":"line\nbreak"},{"email":42}]:
            with self.subTest(values=values), self.assertRaises(ValueError):
                validate(event(body=json.dumps(payload(**values))))

    def test_invalid_json_and_large_body(self):
        for request in [event(body="{"),event(body="x"*4097),
                        event(isBase64Encoded=True),event(body="[]")]:
            with self.assertRaises(ValueError): validate(request)

    def test_authorization_requires_exact_group_and_client(self):
        self.assertTrue(administrator(claims(), "client"))
        self.assertTrue(administrator(claims(**{"cognito:groups":"[administrators other]"}), "client"))
        self.assertFalse(administrator(claims(aud="other"), "client"))
        self.assertFalse(administrator(claims(token_use="access"), "client"))
        self.assertFalse(administrator(claims(**{"cognito:groups":"fake-administrators"}), "client"))

if __name__ == "__main__": unittest.main()
