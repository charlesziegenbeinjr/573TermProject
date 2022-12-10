
k = 14
size = 32

for z in range(k):
    number = z
    lead = "assign c"+str(number)+"_count ="
    body = ""
    for x in range(size-1):
        body = body + " c{}[{}] +".format(number,x)
    body = body + " c{}[{}];".format(number,size-1)
    print(lead+body)
    