#!/usr/bin/env python
import json
import os
import sys

import requests

CIRCLE_API_TOKEN = os.environ["CIRCLE_API_TOKEN"]
CIRCLE_BRANCH = os.environ.get("CIRCLE_BRANCH", "master")
CIRCLE_JOB = "test-accounts"
CIRCLE_API_URL = f"https://circleci.com/api/v1.1/project/github/" \
                   f"openstax/os-automation/tree/{CIRCLE_BRANCH}?circle-token={CIRCLE_API_TOKEN}"

def log(message, file=sys.stderr):
    print(message, file=file)

def read_file(filepath):
    with open(filepath, "r") as infile:
        data = infile.read()
    return data

env = "p-" + read_file("./accounts-git/.git/short_ref").strip()
log(f"Environment detected: {env}")

headers = {"Content-Type": "application/json"}

data = {"build_parameters":
    {
        "CIRCLE_JOB": CIRCLE_JOB,
	"INSTANCE": "unique",
	"ADMIN_USER": "scott",
	"ADMIN_PASSWORD_UNIQUE": os.environ["TEST_PASSWORD"],
	"TEACHER_USER": "teacher@sandbox.openstax.org",
	"TEACHER_PASSWORD_UNIQUE": os.environ["CIRCLE_API_TOKEN"],
	"STUDENT_USER": "student@sandbox.openstax.org",
	"STUDENT_PASSWORD_UNIQUE": os.environ["CIRCLE_API_TOKEN"],
        "ACCOUNTS_BASE_URL": "https://accounts-" + env + ".sandbox.openstax.org"
    }
}

r = requests.post(CIRCLE_API_URL, headers=headers, data=json.dumps(data))

r.raise_for_status()

r = r.json()

build_url = r["build_url"]
log(f"Build URL returned by CircleCI is: {build_url}")

with open("./circleci-output/build-url.txt", "w") as outfile:
    outfile.write(build_url)
