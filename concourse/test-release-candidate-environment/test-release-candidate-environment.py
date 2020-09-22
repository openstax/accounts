#!/usr/bin/env python
import json
import os
import sys

import requests

CIRCLE_API_TOKEN = os.environ["CIRCLE_API_TOKEN"]
CIRCLE_BRANCH = os.environ.get("CIRCLE_BRANCH", "main")
CIRCLE_JOB = "test-accounts"
CIRCLE_API_URL = f"https://circleci.com/api/v1.1/project/github/" \
                   f"openstax/os-automation/tree/{CIRCLE_BRANCH}?circle-token={CIRCLE_API_TOKEN}"
INSTANCE = "unique"
ADMIN_PASSWORD_UNIQUE = os.environ["ADMIN_PASSWORD"]
TEACHER_PASSWORD_UNIQUE = os.environ["TEACHER_PASSWORD"]
STUDENT_PASSWORD_UNIQUE = os.environ["STUDENT_PASSWORD"]

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
        "INSTANCE": INSTANCE,
        "ADMIN_USER": "testadmin",
        "ADMIN_PASSWORD_UNIQUE": ADMIN_PASSWORD_UNIQUE,
        "TEACHER_USER": "teacher+01@sandbox.openstax.org",
        "TEACHER_PASSWORD_UNIQUE": TEACHER_PASSWORD_UNIQUE,
        "STUDENT_USER": "student+01@sandbox.openstax.org",
        "STUDENT_PASSWORD_UNIQUE": STUDENT_PASSWORD_UNIQUE,
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
