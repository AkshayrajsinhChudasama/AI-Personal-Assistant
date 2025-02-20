import json
from google import genai
from google.genai import types
import os

client = genai.Client(api_key="AIzaSyCsVRWHGdVoWUJ4IPsEmYXuZ0Fnhyk4rdc")

def generate_response(prompt):
    response = client.models.generate_content(
        model='gemini-2.0-flash',
        contents=prompt,
        config=types.GenerateContentConfig(
            tools=[types.Tool(
                google_search=types.GoogleSearchRetrieval
            )]
        )
    )

    # Extract the text from the response
    if response and hasattr(response, 'candidates'):
        candidate = response.candidates[0]
        if candidate and hasattr(candidate, 'content'):
            content = candidate.content.parts[0].text
            print(content)
            # Remove leading nn-JSON content (before first '{') and trailing non-JSON content (after last '}')
            start_index = content.find('{')
            end_index = content.rfind('}') + 1
            
            if start_index != -1 and end_index != -1:
                json_content = content[start_index:end_index]
                print(json_content) 
                # Convert the content to JSON format
                try:
                    json_data = json.loads(json_content)
                    print(json_data)
                    return json_data
                except json.JSONDecodeError:
                    print("Error decoding JSON")
                    return None
            else:
                print("No valid JSON content found.")
                return None
