
# This function is used to fix the splited readings.
# For example something like: "+0000] "POST /api/v1/entries.json HTTP/1.1" 200 we combine the "POST /api/v1/entries.json HTTP/1.1" to one entry.
def FixSplit(line):
    ret = []
    adding = False
    tmp = ""
    for word in line:
        word = word.rstrip()
        if word[0] == '"' and word[-1] == '"':
            ret.append(word)
            continue
        if not adding:
            if word[0] == '"':
                adding = True
                tmp = word
            else:
                ret.append(word)
        else:
            tmp = tmp + word
            #print(word, word[-1])
            if word[-1] == '"':
                #print("end of wooors")
                adding = False
                ret.append(tmp)
                tmp=""
    return ret
    

def TrimByChar(str, char):
    pos = str.find(char)
    if pos == -1:
        return str
    return str[0:pos]
       

def CreateHist(lines):
    i = 0
    sum = 0
    agent_hist = {}
    request_hist = {}
    for line in lines:
        split = line.split()
        #print(len(split))

        split1 = FixSplit(split)
        #print(i, split1)
        #print(i, split1[7], split1[9])
        egress = split1[7]
        agent = split1[9]
        request = split1[5]
        request = TrimByChar(request, "?")

       
        request.find('?')
        #print(request)
        sum += int(egress)
        i +=1
        agent_hist[agent] = agent_hist.get(agent, 0) +  int(egress)
        request_hist[request] = request_hist.get(request, 0) +  int(egress)

    print("Total lines in file:", i, "Total egresses traffic", sum)


    # Print the agent_hist based on agent
    print("\nAgent historgram")
    for value, key in sorted( ((v,k) for k,v in agent_hist.items()), reverse=True):
        if value < 100000: continue
        print(key, ' : ', value / 1000000)

    
    print("\nrequest historgram\n")
    # Print the request_his based on agent
    for value, key in sorted( ((v,k) for k,v in request_hist.items()), reverse=True):
        if value < 100000: continue
        print(key, ' : ', value / 1000000)


with open("c:\\Users\\nirit\\Downloads\\access.log") as file:
    lines = [line.rstrip('\n') for line in file]

CreateHist(lines)