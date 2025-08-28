import os
import httpx
import logging # Import logging module
from typing import Optional, List, Dict

logger = logging.getLogger(__name__) # Get logger for this module

class GcpLLMService:
    _instance = None
    _cloud_run_url: Optional[str] = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(GcpLLMService, cls).__new__(cls)
        return cls._instance

    def initialize(self, cloud_run_url: str):
        self._cloud_run_url = cloud_run_url
        logger.info(f"GCP LLM Service initialized with Cloud Run URL: {self._cloud_run_url}")

    async def generate_response(self, prompt: str, chat_history: List[Dict], context: Optional[List[Dict]] = None) -> str:
        if not self._cloud_run_url:
            logger.error("GCP LLM Service not initialized. Call initialize() first.")
            raise Exception("GCP LLM Service not initialized. Call initialize() first.")

        # TODO: Implement Google Cloud Run authentication (e.g., using google-auth library)
        # For now, assuming unauthenticated access or handled by environment.
        # In production, use service account credentials to sign requests.

        request_payload = {
            "prompt": prompt,
            "chat_history": chat_history,
            "context": context if context else []
        }

        async with httpx.AsyncClient() as client:
            try:
                logger.info(f"Sending request to GCP LLM at: {self._cloud_run_url}")
                response = await client.post(
                    self._cloud_run_url,
                    json=request_payload,
                    timeout=300.0 # Long timeout for LLM inference
                )
                response.raise_for_status()
                logger.info("Received successful response from GCP LLM.")
                return response.json().get("response", "No response from GCP LLM.")
            except httpx.RequestError as exc:
                logger.error(f"GCP LLM service communication error: {exc}")
                raise Exception(f"GCP LLM service communication error: {exc}")
            except httpx.HTTPStatusError as exc:
                logger.error(f"GCP LLM service returned error: {exc.response.status_code} - {exc.response.text}")
                raise Exception(f"GCP LLM service returned error: {exc.response.status_code} - {exc.response.text}")

# Singleton instance
gcp_llm_service = GcpLLMService()
