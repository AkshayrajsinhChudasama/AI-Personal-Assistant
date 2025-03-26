from fastapi import FastAPI, HTTPException, Depends, Header
from pydantic import BaseModel
from database.utils1 import deleteMessages, insertTask, retriveAllTask, updateTask, deleteTask,insertMessage,retriveMessages
from GeminiAPI.utils import generalDialog, conflictChecker,messageGenerator,conversaction,check_task_conflict,searchToGoogle,classify
from CalendarAPI.utils import create_google_calendar_event, update_google_calendar_event, delete_google_calendar_event
from fastapi.middleware.cors import CORSMiddleware
import re
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

class QueryInput(BaseModel):
    query: str
    chat_history: str
    stage: str
    email: str

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def extract_access_token(authorization: str = Header(...)):
    match = re.match(r"Bearer (\S+)", authorization)
    if match:
        return match.group(1)
    raise HTTPException(status_code=400, detail="Invalid Authorization header format")

@app.post("/chat")
async def process_query(input: QueryInput, authorization: str = Depends(extract_access_token)):
    try:
        user_input = input.query
        history = input.chat_history
        email = input.email
        access_token = authorization
        logger.info(f"Access Token Received: {access_token}")
        await insertMessage(email,user_input,'user')
        info = await retriveAllTask(email)
        tasks = info.get('data', []) if isinstance(info, dict) else []
        history += f'\nDATARESULT:{tasks}'
        classification_res = classify(user_input,history)
        print(classification_res)
        response = {'text': 'If this message appears then ', 'isInfoIncomplete': False, 'dbAction': 'noaction', 'calendarAction': 'noaction'}
        if(classification_res['res']=='first'):
            response = generalDialog(user_input, history)
            response["nInfo"] = response.get("nInfo", {}) 
            logger.info(f"Generated Response: {response}")

            if not response.get('isInfoIncomplete'):
                db_action = response.get('dbAction')

                if db_action == 'add':
                    payload = response.get('payload', {})
                    if all(k in payload for k in ['startdate', 'starttime', 'enddate', 'endtime']):
                        inter_conflict = check_task_conflict(payload,tasks)
                        conflict_check = conflictChecker(inter_conflict, tasks, 'add',payload,response['text'])
                        print(conflict_check)
                        if not conflict_check.get('isConflict'):
                            response['text'] = conflict_check['response']
                            event_info = create_google_calendar_event(
                                access_token,
                                payload.get('summary', ''),
                                payload.get('desc', ''),
                                payload['startdate'],
                                payload['starttime'],
                                payload['enddate'],
                                payload['endtime'],
                                payload.get('daily', False)
                            )
                            payload['addedToCalendar'] = True
                            temp = await insertTask(email, payload, event_info.get('id'))
                        else:
                            await insertMessage(email,conflict_check['text'],'bot')
                            return conflict_check
                    else:
                        payload['addedToCalendar'] = False
                        temp = await insertTask(email, payload)

                    response['nInfo'].update({
                        'task_id': temp['task_id'],
                        'startdate': payload.get('startdate'),
                        'starttime': payload.get('starttime'),
                        'enddate': payload.get('enddate'),
                        'endtime': payload.get('endtime'),
                        'title':conflict_check.get('title'),
                        'body':conflict_check.get('body'),
                        'title1':conflict_check.get('title1'),
                        'body1':conflict_check.get('body1')
                    })

                    response['intent'] = 'new'

                elif db_action == 'update':
                    updated_payload = response.get('payload', {}).get('updatedPayload', {}).get('task', {})
                    task_id = response.get('payload', {}).get('updatedPayload', {}).get('task_id')

                    if updated_payload.get('addedToCalendar') and task_id:
                        tasks = [t for t in tasks if t.get('task_id') != task_id]
                        inter_conflict = check_task_conflict(updated_payload,tasks)
                        conflict_check = conflictChecker(inter_conflict, tasks, 'update',updated_payload,response['text'])
                        if not conflict_check.get('isConflict'):
                            response['text'] = conflict_check['response']
                            if response.get('calendarAction') == 'add':
                                event_info = create_google_calendar_event(
                                    access_token,
                                    updated_payload.get('summary', ''),
                                    updated_payload.get('desc', ''),
                                    updated_payload['startdate'],
                                    updated_payload['starttime'],
                                    updated_payload['enddate'],
                                    updated_payload['endtime'],
                                    updated_payload.get('daily', False)
                                )
                                response['payload']['updatedPayload']['task_id'] = event_info.get('id')
                            elif response.get('calendarAction') == 'update':
                                update_google_calendar_event(
                                    access_token,
                                    task_id,
                                    updated_payload.get('summary', ''),
                                    updated_payload.get('desc', ''),
                                    updated_payload['startdate'],
                                    updated_payload['starttime'],
                                    updated_payload['enddate'],
                                    updated_payload['endtime'],
                                    updated_payload.get('daily', False)
                                )
                        else:
                            await insertMessage(email,conflict_check['text'],'bot')
                            return conflict_check
                        response['nInfo'].update({
                            'title':conflict_check.get('title'),
                            'body':conflict_check.get('body'),
                            'title1':conflict_check.get('title1'),
                            'body1':conflict_check.get('body1')
                        })
                    await updateTask(task_id, updated_payload, task_id)
                    response['nInfo'].update({
                        'task_id': task_id,
                        'startdate': updated_payload.get('startdate'),
                        'starttime': updated_payload.get('starttime'),
                        'enddate': updated_payload.get('enddate'),
                        'endtime': updated_payload.get('endtime'),
                    })
                    response['intent'] = 'new'

                elif db_action == 'delete':
                    delete_payload = response.get('payload', {}).get('deletePayload', [])
                    response['nInfo']['delete'] = []
                    for obj in delete_payload:
                        if obj.get('addedToCalendar'):
                            delete_google_calendar_event(access_token, obj.get('_id'))
                        await deleteTask(obj.get('_id'))
                        response['nInfo']['delete'].append(obj.get('_id'))
                    response['intent'] = 'new'
            print(response)
        else:
            response['text']=searchToGoogle(user_input,classification_res['history'])
            print(response)
        await insertMessage(email,response['text'],'bot')
        return response
    except Exception as e:        
        logger.error(f"Unexpected error: {e}")

        raise HTTPException(status_code=500, detail="Internal Server Error")

class msg(BaseModel):
    task:str

@app.post("/message")
async def process_query(temp: msg):
    try:
        output = messageGenerator(temp.task)  
        print(output)
        return output
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")

class Conv(BaseModel):
    history:str
    msg:str
    email:str

@app.post("/conv")
async def conv(d:Conv):
    try:
        history = d.history
        msg = d.msg
        email = d.email
        await insertMessage(email,msg,'user')
        output = conversaction(msg, history)
        await insertMessage(email,output['res'],'bot')
        print(output)
        return output  
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    
class retriveDTO(BaseModel):
    email:str

@app.post("/retriveMessages")
async def ret(d:retriveDTO):
    try:
        email = d.email
        res = await retriveMessages(email)
        return res
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
    
@app.post("/deleteMessages")
async def delete_messages(d: retriveDTO):
    try:
        email = d.email
        res = await deleteMessages(email)
        return res
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")