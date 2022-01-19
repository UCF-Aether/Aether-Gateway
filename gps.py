# /usr/bin/python

import io                                                                
import json                                                              

import pynmea2                                                           
from pynmea2.types.talker import GLL                                     

CMD_FIFO_PATH = '/etc/aether/cmd.fifo'                                   
GPS_DEV_PATH = '/dev/ttyAMA0'                                            

# Base event object                                                      
event = {                                                                
    'msgtype': 'event',                                                  
    'type': 'gwstatus'                                                   
}                                                                        

with open(GPS_DEV_PATH, errors='ignore') as f:                           
    while True:                                                          
        line = f.readline()                                              
        msg = pynmea2.parse(line)                                        
        if isinstance(msg, GLL):                                         
            event['latitude'] = msg.latitude                             
            event['longitude'] = msg.longitude                           
            # print(event)                                               
            with open(CMD_FIFO_PATH, 'w') as cmd:                        
                # New line is required for basic station to pick it up   
                cmd.write(f'{json.dumps(event)}\n')                      
                cmd.flush()                                              
            break                                                        
