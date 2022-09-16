*** Settings ***
Documentation     Robot que descarga logs
...               en la plataforma UVirtual
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.Dialogs
Library    Collections
Library    util.py
Library    RPA.Desktop
*** Variables ***
${USUARIO}    %{USUARIO_PROFESOR}
${PASSWORD}   %{PASSWORD}
${ASIGNATURA}    %{ASIGNATURA}

*** Keywords ***
#Este proceso no ingresa el captcha si no que le pide al usuario ingresarlo
#Una vez se cierra sigue el proceso
Ingresar Captcha
    Add icon      Warning
    Add heading   Por favor verifique que es humano para seguir con el proceso y luego haga click en close para continuar
    Run dialog    title=Rellene el captcha    height=350    width=512
    
Ingresar Datos
    Add icon      Warning
    Add heading   Por favor inicie sesion y aprete el boton close una vez haya cargado la pagina
    Run dialog    title=Rellene su informacion    height=350    width=512
#Inicia sesion en la plataforma de UVirtual
Iniciar Sesion
    Input Text    username    ${USUARIO}
    Input Password    password    ${PASSWORD}
    Click Button When Visible    loginbtn

#Ingresa a la plataforma de UVirtual
Abrir UVirtual
    Open Available Browser    https://uvirtual.usach.cl/moodle/init/
    Maximize Browser Window
    #Verifica si
    ${captcha_existe}         Does Page Contain    Estamos verificando que no sea un BOT...
    IF    ${captcha_existe} 
        Ingresar Captcha        
    END
    ${login}    Does Page Contain    Acceda a su cuenta 
    ${usuarioVacio}    String Is Empty    ${USUARIO}
    ${contraseñaVacia}    String Is Empty    ${PASSWORD}

    IF    ${login}
        IF    ${usuarioVacio} == True or ${contraseñaVacia} == True
            Ingresar Datos
        ELSE
            Iniciar Sesion
        END
    END
    Wait Until Page Contains    Mis Cursos    1 min

#Interfaz que se muestra cuando no se logra encontrar el curso
Interfaz Seleccionar Curso
    Add icon      Warning
    Add heading   El robot no ha logrado encontrar el curso, por favor haga click al curso que desea en el que trabaje, espere a que cargue la pagina y luego haga click en Close
    Run dialog    title=Seleccione el curso    height=350    width=512

#Selecciona el curso al que se quiere crear grupos/secciones
Seleccionar Curso
    ${string_vacio}    String Is Empty    ${ASIGNATURA}
    #Verifica si el bot encontro el curso
    ${curso_existe}    Does Page Contain    ${ASIGNATURA}
    #Si existe le hace click
    IF    ${string_vacio}
        Interfaz Seleccionar Curso
    ELSE IF    ${curso_existe}
        Click Link    ${ASIGNATURA}  
    #Si no existe muestra una interfaz
    ELSE
        Interfaz Seleccionar Curso
    END
    #Espera a que cargue el curso
    Wait Until Page Contains Element    id:region-main-box    1 min

Apretar Configuracion
    Click Element When Visible    id:dropdown-2
    Click Element When Visible    link:Más ...
    Wait Until Page Contains    Administración del curso
Ir a Registros
    Click Element When Visible    link:Registros
    Wait Until Page Contains    Seleccione los registros que desea ver:  
    Select From List By Index    id:menudate    0
    Click Button When Visible    xpath://input[@value='Conseguir estos registros']
    Wait Until Page Contains    Nombre completo del usuario

Obtener Largo Listas
    ${lista}    Get List Items    id:menudate
    ${largoLista}    Get Input List Size    ${lista} 
    [Return]    ${largoLista}

Interfaz Cantidad de Dias
    Add heading     Seleccione cuanto tiempo
    Add drop-down
    ...    name=cantidad_semanas
    ...    options=1 semana,2 semanas,3 semanas,4 semanas
    ...    default=1 semana
    ...    label=cantidad de semanas
    ${cantidad}=      Run dialog    height=350    width=512
    [Return]    ${cantidad}

Seleccionar Cantidad de Dias
    [Arguments]    ${cantidadSemanas}
    ${cantidadSemanas}    Get Weekends    ${cantidadSemanas}
    IF    ${cantidadSemanas} == 1
        ${cantidadSemanas}    Evaluate    7
    ELSE IF    ${cantidadSemanas} == 2
        ${cantidadSemanas}    Evaluate    14
    ELSE IF    ${cantidadSemanas} == 3
        ${cantidadSemanas}    Evaluate    21
    ELSE IF    ${cantidadSemanas} == 4
        ${cantidadSemanas}    Evaluate    28
    ELSE IF    ${cantidadSemanas} == 5
        ${cantidadSemanas}    Evaluate    35
    ELSE IF    ${cantidadSemanas} == 6
        ${cantidadSemanas}    Evaluate    42
    END
    [Return]    ${cantidadSemanas}

Descargar Log
    [Arguments]    ${index}
    Select From List By Index    id:menudate    ${index}
    Click Button When Visible    xpath://input[@value='Conseguir estos registros']
    Wait Until Page Contains Element    xpath://input[@value='Conseguir estos registros']
    ${hayLogs}    Does Page Contain    Nada que mostrar
    IF    ${hayLogs} == False
        Click Button    xpath://button[@type='submit']
        Wait Seconds    1
    END
    

Descargar Logs
    [Arguments]    ${largoLista}    ${cantidadDias}
    ${index}    Evaluate    1
    IF    ${largoLista} < ${cantidadDias} + 1
        WHILE  ${index} < ${largoLista}
            Descargar Log   ${index}
            ${index}    Evaluate    ${index} + 1
        END
    ELSE
        WHILE  ${index} < ${cantidadDias} + 1
            Descargar Log    ${index}
            ${index}    Evaluate    ${index} + 1
        END
    END

Interfaz Final
    Add heading    El proceso ha terminado, cierre esto. Los logs estan en la carpeta de descargas original de su PC (C:\Users\NombreUsuario\Downloads)
    Run dialog    title=Cierre esto    height=350    width=512
*** Tasks ***
Minimal task
    Abrir UVirtual
    Seleccionar Curso
    Apretar Configuracion
    Ir a Registros
    ${largoLista}    Obtener Largo Listas
    ${cantidadSemanas}    Interfaz Cantidad de Dias
    ${cantidadDias}    Seleccionar Cantidad de Dias    ${cantidadSemanas}[cantidad_semanas]
    Descargar Logs    ${largoLista}    ${cantidadDias}
    Interfaz Final


