#!/usr/bin/env python3
import subprocess
import yaml
import os
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[2]
INFISICAL_YML = ROOT_DIR / "infisical.yml"
INFISICAL_ENV = ROOT_DIR / ".infisical.env"


def load_required_vars():
    with open(INFISICAL_YML, "r") as f:
        data = yaml.safe_load(f)

    if "required_vars" not in data:
        raise ValueError("Missing 'required_vars' key in infisical.yml")

    return data["required_vars"]


def load_env():
    if not INFISICAL_ENV.exists():
        raise FileNotFoundError(".infisical.env not found")

    env = os.environ.copy()
    with open(INFISICAL_ENV) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            k, v = line.split("=", 1)
            env[k] = v
    return env


def fetch_secrets(env_name, env):
    cmd = [
        "infisical",
        "secrets",
        "--projectId", env["INFISICAL_SECRETS_PROJECTID"],
        "--env", env_name,
        "--recursive",
        "--output", "dotenv",
        "--silent",
    ]

    result = subprocess.run(
        cmd,
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )

    secrets = {}
    for line in result.stdout.splitlines():
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        secrets[k] = v

    return secrets


def main():
    required = load_required_vars()
    env = load_env()

    for env_name, var_list in required.items():
        prefix = env_name.upper()
        secrets = fetch_secrets(env_name, env)

        print(f"\n# Environment: {env_name}")

        for var in var_list:
            if var not in secrets:
                print(f"# WARNING: {var} not found in Infisical ({env_name})", file=sys.stderr)
                continue

            print(f"{prefix}_{var}={secrets[var]}")


if __name__ == "__main__":
    main()
