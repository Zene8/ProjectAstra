from llama_cpp import Llama
import os
import logging # Import logging module
from typing import Optional, List, Dict

logger = logging.getLogger(__name__) # Get logger for this module

class LocalLLMService:
    _instance = None
    _llm: Optional[Llama] = None
    _model_path: Optional[str] = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(LocalLLMService, cls).__new__(cls)
        return cls._instance

    def load_model(self, model_path: str, n_gpu_layers: int = 0):
        # n_gpu_layers: Number of layers to offload to GPU. Set to 0 for CPU only.
        # For optimal performance, use quantized models (e.g., GGUF Q4_K_M)
        if self._llm is None or self._model_path != model_path:
            logger.info(f"Loading LLM model from: {model_path}")
            if not os.path.exists(model_path):
                logger.error(f"Model file not found at: {model_path}")
                raise FileNotFoundError(f"Model file not found at: {model_path}")
            self._llm = Llama(model_path=model_path, n_gpu_layers=n_gpu_layers)
            self._model_path = model_path
            logger.info("LLM model loaded successfully.")
        else:
            logger.info(f"Model {model_path} already loaded.")

    def generate_response(self, prompt: str, chat_history: List[Dict], context: Optional[List[Dict]] = None) -> str:
        if self._llm is None:
            logger.error("LLM model not loaded. Call load_model() first.")
            raise Exception("LLM model not loaded. Call load_model() first.")

        # Construct the full prompt including chat history and context
        full_prompt = ""
        if context:
            full_prompt += "Context: " + ", ".join([f"{c.get('appName', '')}: {c.get('activeItemContent', '')}" for c in context]) + "\n"
        
        for entry in chat_history:
            full_prompt += f"User: {entry.get('message', '')}\n"
            full_prompt += f"Assistant: {entry.get('response', '')}\n"
        
        full_prompt += f"User: {prompt}\nAssistant:"

        logger.info(f"Generating response with prompt: {full_prompt}")
        output = self._llm(
            full_prompt,
            max_tokens=256, # TODO: Make configurable
            stop=["User:", "Assistant:"], # TODO: Make configurable
            echo=False,
        )
        return output["choices"][0]["text"]

# Singleton instance
local_llm_service = LocalLLMService()