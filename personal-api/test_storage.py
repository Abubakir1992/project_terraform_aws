import json
import unittest
from unittest.mock import patch, MagicMock
from test_support import contacts, database, event

class StorageTests(unittest.TestCase):
    def test_pii_stays_out_of_queue(self):
        with patch("contacts.execute") as execute, patch("contacts.queue") as queue:
            result = contacts.create_contact(event())
        self.assertEqual(result["message"], "Our agent will call you.")
        metadata = json.loads(queue.send_message.call_args.kwargs["MessageBody"])
        self.assertEqual(set(metadata), {"requestId", "interest", "date"})
        self.assertNotIn("rider@example.com", json.dumps(metadata))
        self.assertIn("INSERT IGNORE", execute.call_args_list[1].args[0])

    def test_queue_failure_does_not_report_success(self):
        with patch("contacts.execute"), patch("contacts.queue") as queue:
            queue.send_message.side_effect = RuntimeError("unavailable")
            with self.assertRaises(RuntimeError): contacts.create_contact(event())

    def test_sql_uses_parameters(self):
        with patch("database.client") as client:
            database.execute("SELECT :name", {"name": "'; DROP TABLE people;--"})
            args = client.execute_statement.call_args.kwargs
        self.assertEqual(args["sql"], "SELECT :name")
        self.assertEqual(args["parameters"][0]["value"]["stringValue"], "'; DROP TABLE people;--")

    def test_pagination_limit(self):
        records = [[{"stringValue":str(i)}] for i in range(51)]
        with patch("database.execute", side_effect=[{}, {"records":records}]):
            result = database.list_contacts({})
        self.assertEqual(len(result["people"]),50)
        self.assertEqual(result["next_cursor"],"49")

if __name__ == "__main__": unittest.main()
