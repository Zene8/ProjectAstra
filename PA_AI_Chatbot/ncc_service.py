

import os
import subprocess
import uuid
import asyncio
from typing import Tuple
from config import (
    NCC_USER,
    NCC_HOST,
    NCC_PRIVATE_KEY_PATH,
    NCC_REMOTE_JOB_DIR,
    NCC_REMOTE_INFERENCE_SCRIPT_PATH,
    NCC_REMOTE_VENV_PATH,
)

async def run_inference_on_ncc(prompt: str, chat_history: list) -> Tuple[str, str]:
    session_id = str(uuid.uuid4())
    remote_session_dir = f"{NCC_REMOTE_JOB_DIR}/{session_id}"
    local_session_dir = f"/tmp/{session_id}"

    os.makedirs(local_session_dir, exist_ok=True)

    # Serialize chat history and prompt
    with open(f"{local_session_dir}/input.txt", "w") as f:
        f.write(f"{prompt}\n")
        for entry in chat_history:
            f.write(f"{entry['message']}\n{entry['response']}\n")

    # Generate SLURM script
    slurm_script = f"""#!/bin/bash
#SBATCH --job-name=llm-inference-{session_id}
#SBATCH --output={remote_session_dir}/output.log
#SBATCH --error={remote_session_dir}/error.log
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=00:10:00

source {NCC_REMOTE_VENV_PATH}
python {NCC_REMOTE_INFERENCE_SCRIPT_PATH} {remote_session_dir}/input.txt {remote_session_dir}/output.txt
"""
    with open(f"{local_session_dir}/run_inference.slurm", "w") as f:
        f.write(slurm_script)

    # SSH commands
    ssh_command = ["ssh", "-i", NCC_PRIVATE_KEY_PATH, f"{NCC_USER}@{NCC_HOST}"]
    
    # Create remote directory
    subprocess.run(ssh_command + [f"mkdir -p {remote_session_dir}"], check=True)

    # SCP files to NCC
    scp_command = ["scp", "-i", NCC_PRIVATE_KEY_PATH]
    subprocess.run(scp_command + [f"{local_session_dir}/input.txt", f"{local_session_dir}/run_inference.slurm", f"{NCC_USER}@{NCC_HOST}:{remote_session_dir}/"], check=True)

    # Submit SLURM job
    submit_process = subprocess.run(ssh_command + [f"sbatch {remote_session_dir}/run_inference.slurm"], capture_output=True, text=True, check=True)
    job_id = submit_process.stdout.strip().split()[-1]

    # Monitor job status
    while True:
        status_process = subprocess.run(ssh_command + [f"squeue -j {job_id}"], capture_output=True, text=True, check=True)
        if job_id not in status_process.stdout:
            break
        await asyncio.sleep(10)

    # SCP results back
    subprocess.run(scp_command + [f"{NCC_USER}@{NCC_HOST}:{remote_session_dir}/output.txt", f"{local_session_dir}/"], check=True)
    
    with open(f"{local_session_dir}/output.txt", "r") as f:
        response = f.read()

    # Cleanup
    subprocess.run(ssh_command + [f"rm -rf {remote_session_dir}"], check=True)
    os.remove(f"{local_session_dir}/input.txt")
    os.remove(f"{local_session_dir}/run_inference.slurm")
    os.remove(f"{local_session_dir}/output.txt")
    os.rmdir(local_session_dir)

    return response, session_id

