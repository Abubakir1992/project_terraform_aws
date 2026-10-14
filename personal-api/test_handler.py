import importlib
import json
import os
import sys
import types
import unittest
from unittest.mock import Mock

fake = Mock()
sys.modules["boto3"] = types.SimpleNamespace(client=lambda service: fake)
api = importlib.import_module("handler")


class HandlerTests(unittest.TestCase):
    def setUp(self):
        fake.reset_mock()
        fake.execute_statement.side_effect = None
        api.schema_ready = False
        os.environ.update(CLUSTER_ARN="cluster", SECRET_ARN="secret", DATABASE="personal_data")
        self.event = {
            "requestContext": {"http": {"method": "PUT"}, "authorizer": {
                "jwt": {"claims": {"sub": "user-123"}}}},
            "body": json.dumps({"full_name": "Ada", "email": "ada@example.com", "phone": "", "address": ""})
        }

    def test_unauthenticated_does_not_touch_database(self):
        self.event["requestContext"].pop("authorizer")
        self.assertEqual(api.handler(self.event, None)["statusCode"], 401)
        fake.execute_statement.assert_not_called()

    def test_invalid_and_oversized_input(self):
        for body in ['null', '[]', '{', '{"email":"invalid"}', 'x' * 8193]:
            self.event["body"] = body
            self.assertEqual(api.handler(self.event, None)["statusCode"], 400)
        fake.execute_statement.assert_not_called()

    def test_owner_cannot_be_supplied_by_browser(self):
        data = json.loads(self.event["body"])
        data["owner_sub"] = "someone-else"
        self.event["body"] = json.dumps(data)
        self.assertEqual(api.handler(self.event, None)["statusCode"], 400)
        fake.execute_statement.assert_not_called()

    def test_sql_input_is_bound_and_owner_comes_from_jwt(self):
        data = json.loads(self.event["body"])
        data["full_name"] = "'); DROP TABLE people; --"
        self.event["body"] = json.dumps(data)
        self.assertEqual(api.handler(self.event, None)["statusCode"], 200)
        call = fake.execute_statement.call_args.kwargs
        self.assertNotIn(data["full_name"], call["sql"])
        values = {p["name"]: p["value"]["stringValue"] for p in call["parameters"]}
        self.assertEqual(values["owner_sub"], "user-123")
        self.assertEqual(values["full_name"], data["full_name"])

    def test_schema_only_once_and_retries_are_upserts(self):
        api.handler(self.event, None)
        api.handler(self.event, None)
        self.assertEqual(fake.execute_statement.call_count, 3)
        self.assertIn("ON DUPLICATE KEY UPDATE", fake.execute_statement.call_args.kwargs["sql"])

    def test_database_failure_has_no_sensitive_error_details(self):
        fake.execute_statement.side_effect = Exception("private database details")
        result = api.handler(self.event, None)
        self.assertEqual(result["statusCode"], 503)
        self.assertNotIn("private", result["body"])


if __name__ == "__main__":
    unittest.main()
