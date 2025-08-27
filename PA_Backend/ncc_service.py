

import os
import uuid
import asyncio
import paramiko
from typing import Tuple, Optional
from config (
    NCC_USER,
    NCC_HOST,
    NCC_PRIVATE_KEY_PATH,
    NCC_REMOTE_JOB_DIR,
    NCC_REMOTE_INFERENCE_SCRIPT_PATH,
    NCC_REMOTE_VENV_PATH,
)

class NCCService:
    def __init__(self):
        self.client = paramiko.SSHClient()
        self.client.load_system_host_keys()
        self.client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            self.client.connect(
                hostname=NCC_HOST,
                username=NCC_USER,
                key_filename=NCC_PRIVATE_KEY_PATH
            )
        except paramiko.AuthenticationException:
            raise Exception("Authentication failed, please verify your credentials and key path.")
        except paramiko.SSHException as e:
            raise Exception(f"Could not establish SSH connection: {e}")

    def _execute_command(self, command: str) -> Tuple[str, str]:
        stdin, stdout, stderr = self.client.exec_command(command)
        return stdout.read().decode().strip(), stderr.read().decode().strip()

    def _sftp_put(self, local_path: str, remote_path: str):
        sftp = self.client.open_sftp()
        sftp.put(local_path, remote_path)
        sftp.close()

    def _sftp_get(self, remote_path: str, local_path: str):
        sftp = self.client.open_sftp()
        sftp.get(remote_path, local_path)
        sftp.close()

    async def run_slurm_job(self, slurm_script_path: str, remote_job_dir: str, output_filename: str) -> str:
        # Create remote directory
        stdout, stderr = self._execute_command(f"mkdir -p {remote_job_dir}")
        if stderr:
            raise Exception(f"Error creating remote directory: {stderr}")

        # Submit SLURM job
        stdout, stderr = self._execute_command(f"sbatch {slurm_script_path}")
        if stderr and "Submitted batch job" not in stderr: # sbatch often prints job ID to stderr
            raise Exception(f"Error submitting SLURM job: {stderr}")
        
        job_id = stdout.strip().split()[-1] if stdout else stderr.strip().split()[-1]

        # Monitor job status
        while True:
            stdout, stderr = self._execute_command(f"squeue -j {job_id}")
            if job_id not in stdout:
                break
            await asyncio.sleep(10)

        # Check for job errors (optional, but good practice)
        stdout, stderr = self._execute_command(f"cat {remote_job_dir}/error.log")
        if stdout:
            print(f"SLURM Job Error Log: {stdout}") # Log errors, don't necessarily raise

        return job_id

    async def run_inference_on_ncc(self, prompt: str, chat_history: list) -> Tuple[str, str]:
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
        slurm_script_content = f"""#!/bin/bash
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
        slurm_script_local_path = f"{local_session_dir}/run_inference.slurm"
        with open(slurm_script_local_path, "w") as f:
            f.write(slurm_script_content)

        # Transfer files to NCC
        self._sftp_put(f"{local_session_dir}/input.txt", f"{remote_session_dir}/input.txt")
        self._sftp_put(slurm_script_local_path, f"{remote_session_dir}/run_inference.slurm")

        # Run SLURM job
        job_id = await self.run_slurm_job(f"{remote_session_dir}/run_inference.slurm", remote_session_dir, "output.txt")

        # SCP results back
        output_remote_path = f"{remote_session_dir}/output.txt"
        output_local_path = f"{local_session_dir}/output.txt"
        self._sftp_get(output_remote_path, output_local_path)
        
        with open(output_local_path, "r") as f:
            response = f.read()

        # Cleanup
        self._execute_command(f"rm -rf {remote_session_dir}")
        os.remove(f"{local_session_dir}/input.txt")
        os.remove(slurm_script_local_path)
        os.remove(output_local_path)
        os.rmdir(local_session_dir)

        return response, session_id

    async def run_compute_on_ncc(self, python_script_content: str, input_data: Optional[str] = None) -> str:
        session_id = str(uuid.uuid4())
        remote_session_dir = f"{NCC_REMOTE_JOB_DIR}/{session_id}"
        local_session_dir = f"/tmp/{session_id}"

        os.makedirs(local_session_dir, exist_ok=True)

        # Write Python script to local file
        python_script_local_path = f"{local_session_dir}/compute_script.py"
        with open(python_script_local_path, "w") as f:
            f.write(python_script_content)

        # Write input data to local file if provided
        input_local_path = None
        if input_data:
            input_local_path = f"{local_session_dir}/input_data.txt"
            with open(input_local_path, "w") as f:
                f.write(input_data)

        # Generate SLURM script
        slurm_script_content = f"""#!/bin/bash
#SBATCH --job-name=generic-compute-{session_id}
#SBATCH --output={remote_session_dir}/output.log
#SBATCH --error={remote_session_dir}/error.log
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:05:00

source {NCC_REMOTE_VENV_PATH}
python {remote_session_dir}/compute_script.py {remote_session_dir}/input_data.txt {remote_session_dir}/output.txt
"""
        slurm_script_local_path = f"{local_session_dir}/run_compute.slurm"
        with open(slurm_script_local_path, "w") as f:
            f.write(slurm_script_content)

        # Transfer files to NCC
        self._sftp_put(python_script_local_path, f"{remote_session_dir}/compute_script.py")
        if input_local_path:
            self._sftp_put(input_local_path, f"{remote_session_dir}/input_data.txt")
        self._sftp_put(slurm_script_local_path, f"{remote_session_dir}/run_compute.slurm")

        # Run SLURM job
        job_id = await self.run_slurm_job(f"{remote_session_dir}/run_compute.slurm", remote_session_dir, "output.txt")

        # SCP results back
        output_remote_path = f"{remote_session_dir}/output.txt"
        output_local_path = f"{local_session_dir}/output.txt"
        self._sftp_get(output_remote_path, output_local_path)
        
        with open(output_local_path, "r") as f:
            response = f.read()

        # Cleanup
        self._execute_command(f"rm -rf {remote_session_dir}")
        os.remove(python_script_local_path)
        if input_local_path:
            os.remove(input_local_path)
        os.remove(slurm_script_local_path)
        os.remove(output_local_path)
        os.rmdir(local_session_dir)

        return response

