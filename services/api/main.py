# Create a FastAPI server and define the endpoints: /embedding, /chat as POST requests
# /embedding: takes a text input and returns the embedding from a remote api call using requests
# /chat: takes a text input and context and returns a response from a remote api call using requests
# Note: the remote api calls are defined in the config file

import os
import sys
import json
import pandas as pd
from typing import List, Optional, Dict
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from langchain.prompts import (
    ChatPromptTemplate,
    MessagesPlaceholder,
    SystemMessagePromptTemplate,
    HumanMessagePromptTemplate,
)
from langchain.embeddings import SagemakerEndpointEmbeddings
from langchain.embeddings.sagemaker_endpoint import EmbeddingsContentHandler
from langchain.llms import SagemakerEndpoint
from langchain.chains import RetrievalQA
from langchain.llms.sagemaker_endpoint import LLMContentHandler
from contextualize import Contextualizer
from langchain.chains import LLMChain  
from langchain.memory import ConversationSummaryMemory
import db
from langchain.memory import ConversationBufferMemory

memory = ConversationBufferMemory()

db_conn = db.init()

### System Prompt
system_prompt = """
    You are a helpful customer service agent working for Kai Shoes. \n
    You will be chatting with a customer. \n
    Use context from their previous orders to help them make decisions.
    """

# Add the parent directory to the path to import the config file
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

SAGEMAKER_ENDPOINT = os.getenv("SAGEMAKER_ENDPOINT")
SAGEMAKER_ROLE = os.getenv("SAGEMAKER_ROLE")
SAGEMAKER_REGION = os.getenv("SAGEMAKER_REGION")
AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
COMMITHASH = os.getenv("COMMITHASH")

print(COMMITHASH)

print(AWS_ACCESS_KEY_ID)
print(AWS_SECRET_ACCESS_KEY)


# Initialize the FastAPI server
app = FastAPI(
    title="LLM API",
    description="API for the LLM project",
    version="0.1.0",
    docs_url="/",
)

## FastAPI Routes
### /chat route

"""
Expected JSON:

{
    "text": "this is my message",
    "cust_id": "1234"
}
"""
@app.post("/chat")
async def chat(request: Request):
    """
    Takes a text input and context and returns a response from a remote api call using requests
    """
    # Get the request body
    body = await request.json()
    # Get the text input
    print(body)
    question = body.get("text")

    # Get the context
    context = body.get("cust_id")


    # Get the response from the LLMChain
    response = llm_prompt_run(context, question)
    # Return the response
    return {"response": response}

@app.get("/test")
async def root():
    return {"message": "Hello World, I'm runnin on commit {}".format(COMMITHASH)}



# SageMaker Endpoint Handler
class ContentHandler(LLMContentHandler):
    content_type = "application/json"
    accepts = "application/json"

    def transform_input(self, prompt: str, model_kwargs: dict) -> bytes:
        # payload = {
        #     "inputs": [
        #             {
        #                 "role": "system",
        #                 "content": system_prompt,
        #             },
        #             {"role": "user", "content": prompt},
                
        #     ],
        #     "parameters": {"max_new_tokens": 1000, "top_p": 0.9, "temperature": 0.6},
        # }
        input_str = ''.join(prompt)
        input_str = json.dumps({"inputs": input_str, "parameters": model_kwargs})
        print(input_str)
        # input_str = json.dumps(
        #     payload,
        # )
        input_utf = input_str
        print(input_utf)
        return input_utf

    def transform_output(self, output: bytes) -> str:
        response_json = json.loads(output.read().decode("utf-8"))
        content = response_json
        return content

content_handler = ContentHandler()

# # SageMaker Embeddings
# sagemaker_embeddings = SagemakerEndpointEmbeddings(
#     endpoint_name=SAGEMAKER_ENDPOINT,
#     region_name=SAGEMAKER_REGION,
#     content_handler=content_handler,
# )

# query_result = sagemaker_embeddings.embed_query("foo")


def llm_prompt_run(user_context, question):

    prompt = ChatPromptTemplate(
        messages=[
            SystemMessagePromptTemplate.from_template(
                "You are a friendly support rep at Kai Shoes. Use the following pieces of information to answer the user's question. If you don't know the answer, just say that you don't know, don't try to make up an answer."
            ),
            MessagesPlaceholder(variable_name="chat_history"),
            HumanMessagePromptTemplate.from_template("{context}"),
            HumanMessagePromptTemplate.from_template("{question}")
        ]
    )

    # SageMaker LLMChain
    llm = SagemakerEndpoint(
        endpoint_name=SAGEMAKER_ENDPOINT,
        region_name="us-west-2",
        model_kwargs={"max_new_tokens": 700, "top_p": 0.9, "temperature": 0.6},
        endpoint_kwargs={"CustomAttributes": 'accept_eula=true'},
        content_handler=content_handler,
    )

    chat_history = []
    memory = ConversationBufferMemory(memory_key="chat_history",return_messages=True)

    chain = LLMChain(llm=llm, 
                    prompt=prompt,
                    memory=memory,
                    )
    

    llm_resp = chain.run({'context': user_context, 'question': question, 'chat_history': chat_history})
    
    print(llm_resp)
    return llm_resp