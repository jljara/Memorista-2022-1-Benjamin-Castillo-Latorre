from multiprocessing.connection import wait
import time
#Funcion que añade comillas simples ('') a un string
#Entrada: un string
#Salida: un string
def add_quotes_to_string(string):
    #si es un string vacio, lo retorna
    if(not string):
        return  string
    #Si no es vacio, lo entrega con comillas
    else:
        return repr(string)

#Funcion que verifica si un string es vacio
#Entrada: un string
#Salida: un booleano
def string_is_empty(string):
    if(string):
        return False
    else:
        return True

def get_intentos(text):
    aux = text.split(": ")[1]
    return aux

def concat_names(names, surname1,surname2):
    return names + " " + surname1 + " " + surname2

def strings_should_be_equal(string1,string2):
    return string1 == string2

def generate_group_text(group):
    group = str(group).strip("''")
    return "'Miembros de: " + group + "'"

def concat_strings(string1,string2):
    return  string1 + string2
    
def wait_seconds(seconds):
    seconds = float(seconds)
    time.sleep(seconds)

def get_position_in_table(position):
    path = 'xpath://tr[' + str(position) + ']/td[4]/a[3]'
    return path

def string_to_float(string,boolean):
    if(string == "-"):
        return "No rendida"
    else:
        string = string.split(",")
        integer = int(string[0])
        decimal = float(int(string[1]) /100)
        number = integer + decimal
        if(boolean):
            number +=1
        
        return number

def format_table_name(name):
    realName = name.replace("Revisión del intento","")
    return realName