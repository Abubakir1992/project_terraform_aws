import json
import unittest
from unittest.mock import patch
from test_support import handler, event, claims, payload

class AccessTests(unittest.TestCase):
    def test_public_cannot_list(self):
        request = event(httpMethod="GET", path="/api/people")
        with patch("handler.list_contacts") as read:
            self.assertEqual(handler.handler(request, None)["statusCode"], 403)
            read.assert_not_called()

    def test_authenticated_non_admin_cannot_list(self):
        request = event(httpMethod="GET", path="/api/people", requestContext={
            "authorizer": {"claims": claims(**{"cognito:groups": "customers"})}})
        with patch("handler.list_contacts") as read:
            self.assertEqual(handler.handler(request, None)["statusCode"], 403)
            read.assert_not_called()

    def test_admin_can_list(self):
        request = event(httpMethod="GET", path="/api/people", requestContext={
            "authorizer": {"claims": claims()}})
        with patch("handler.list_contacts", return_value={"people": [], "next_cursor": ""}):
            response = handler.handler(request, None)
        self.assertEqual(response["statusCode"], 200)
        self.assertEqual(response["headers"]["Cache-Control"], "no-store")

    def test_success_only_after_storage_and_queue(self):
        with patch("handler.create_contact", return_value={"message": "Our agent will call you."}):
            self.assertEqual(handler.handler(event(), None)["statusCode"], 202)
        with patch("handler.create_contact", side_effect=RuntimeError("secret error")):
            response = handler.handler(event(), None)
        self.assertEqual(response["statusCode"], 503)
        self.assertNotIn("secret error", response["body"])

    def test_removed_personal_record_route_is_not_exposed(self):
        self.assertEqual(handler.handler(event(path="/personal-data"), None)["statusCode"], 404)

if __name__ == "__main__": unittest.main()
