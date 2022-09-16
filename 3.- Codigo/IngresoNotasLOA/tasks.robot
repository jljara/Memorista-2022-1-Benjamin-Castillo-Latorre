*** Settings ***
Documentation       Template robot main suite.

Library    RPA.Browser.Selenium    auto_close=${False}
Library    tables.py
Library    util.py
Library    RPA.Tables
Library    RPA.Excel.Files
Library    RPA.Dialogs

*** Variables ***
${EXCEL}    devdata/Notas.xlsx
${USUARIO}    %{USUARIO_PROFESOR}
${PASSWORD}    %{PASSWORD}
${ASIGNATURA}    %{ASIGNATURA}
${CODIGO}    %{CODIGO_ASIGNATURA}

*** Keywords ***
#Funcion que obtiene lee una tabla html
Get HTML table
    ${html_table}=    Get Element Attribute    tbl_cursos    outerHTML
    [Return]    ${html_table}

#Funcion que transforma una tabla html al formato Table de robot framework
#Salida: Una tabla en formato Table
Read HTML table as Table
    #Leer la tabla html
    ${html_table}=    Get HTML table
    #Transformar la tabla html a una tabla
    ${table}=    Read Table From Html    ${html_table}
    [Return]    ${table}

#Funcion que obtiene los cursos
Obtener Cursos
    ${table}    Read HTML table as Table
    ${nombreColumnas}    Create List    tipo2    codigo    nombre    alumnos    pond    porcentaje    horario    jornada    accion
    Rename Table Columns    ${table}    ${nombreColumnas}
    Pop Table Column    ${table}    tipo2
    Pop Table Column    ${table}    pond
    Pop Table Column    ${table}    porcentaje
    Pop Table Column    ${table}    horario
    Pop Table Column    ${table}    accion
    [Return]    ${table}

    
Open the intranet website
    Open Available Browser        https://loa.usach.cl/intranetfing/indexProfesor.jsp
    Wait Until Page Contains    Intranet Docentes
    
Iniciar Sesion en LOA
    ${rutVacio}    String Is Empty    ${USUARIO}
    ${claveVacia}    String Is Empty     ${PASSWORD}
    IF    ${rutVacio} or ${claveVacia}
        Add heading    Iniciar sesion
        Add text input        username    label=RUT
        Add password input    password    label=Contraseña
        ${result}=    Run dialog
        ${USUARIO}    Set Variable    ${result.username}
        ${PASSWORD}    Set Variable    ${result.password}
    END  
    Input Text    id:rutaux    ${USUARIO}
    Input Password    id:clave    ${PASSWORD}
    Submit Form
    Wait Until Element Is Visible    id:menu-profesor
    Click Link    Mis Cursos
    Click Link    Listado Cursos
    Wait Until Element Is Visible    tag:iframe

Click Curso
    [Arguments]    ${codigoCurso}
    Click Element    xpath=//td[contains(.,'${CODIGO}')]
    Wait Until Page Contains    Datos del curso

Ir a Curso
    Select Frame    mainFrame
    Wait Until Element Is Visible    tag:iframe
    Select Frame    if_coord
    ${cursos}    Obtener Cursos
    FOR    ${curso}    IN    @{cursos}
        ${codigosIguales}    Strings Should Be Equal    ${curso}[codigo]    ${CODIGO}
        ${nombresIguales}    Strings Should Be Equal    ${curso}[nombre]    ${ASIGNATURA}
        IF    ${codigosIguales}
            Click Curso    ${curso}[codigo]
        ELSE IF    ${nombresIguales}
            Click Curso    ${curso}[nombre]
        END
    END
    Log    Done

Ir a Zona Calificaciones
    Click Element    //*[@id="toolbar-menu-curso"]/div[1]/a[6]/i
    Wait Until Page Contains    Listado evaluaciones parciales

Ingresar Notas
    [Arguments]    ${evaluacion}
    Open Workbook    ${EXCEL}
    Set Active Worksheet    Notas
    ${archivo}    Read Worksheet As Table    header=True
    Close Workbook
    FOR    ${i}    IN RANGE    1    500
        ${existeCelda}    Does Page Contain Element    //*[@id="frm-evaluacion"]/table/tbody/tr[${i}]/td[4]/input
        IF    ${existeCelda} == True
            ${rut}    Get Element Attribute     //*[@id="frm-evaluacion"]/table/tbody/tr[${i}]/td[2]    innerHTML
            ${nombre}    Get Element Attribute    //*[@id="frm-evaluacion"]/table/tbody/tr[${i}]/td[3]    innerHTML
            ${alumnoRut}    Find Table Rows    ${archivo}    RUN    contains    ${rut}
            ${alumnoNombre}    Find Table Rows    ${archivo}    Nombre    contains    ${nombre}
            ${rowsRut}  ${columnsRut}=    Get table dimensions    ${alumnoRut}
            ${rowsNombre}  ${columnsNombre}=    Get table dimensions    ${alumnoNombre}
            IF    ${rowsRut} == 1
                ${nota}    RPA.Tables.Get Table Cell    ${alumnoRut}    0    ${evaluacion}
                Input Text    //*[@id="frm-evaluacion"]/table/tbody/tr[${i}]/td[4]/input    ${nota}
            ELSE IF    ${rowsNombre} == 1
                ${nota}    RPA.Tables.Get Table Cell    ${alumnoNombre}    0    ${evaluacion}
                Input Text    //*[@id="frm-evaluacion"]/table/tbody/tr[${i}]/td[4]/input    ${nota}
            END
        ELSE
            Click Button    //button[contains(., 'GUARDAR NOTAS')]
            Wait Until Element Is Visible    //div[contains(@class, 'modal-footer')]/button[2]
            Click Button    //div[contains(@class, 'modal-footer')]/button[2]
            Wait Until Page Contains    Listado evaluaciones parciales
            BREAK
        END
    END

#Funcion que ingresa a una evaluacion en especifico y coloca las notas de los estudiante
Ingresar a Evaluacion y Colocar Notas
    #Nombre de la evaluacion actual
    [Arguments]    ${evaluacion}
    FOR    ${i}    IN RANGE    1    500
        #En la tabla ponen en grande Control o el tipo de evaluacin para indicar a partir de la siguiente
        #fila empezaran a mostras las evaluaciones, se verifica si es un enunciado o una evaluacion
        ${esEvaluacion}    Does Page Contain Element    //*[@id="tbl-evaluaciones"]/tbody/tr[${i}]/td[1]/span
        #Esto es para verificar si ya no quedan mas columnas en la tabla
        ${existeEnLaTabla}    Does Page Contain Element    //*[@id="tbl-evaluaciones"]/tbody/tr[${i}]
        #Si aun se esta en una celda de la tabla
        IF    ${esEvaluacion} and ${existeEnLaTabla}
            #Se obtiene el valor de la celda i
            ${evaluacionTabla}    Get Element Attribute     //*[@id="tbl-evaluaciones"]/tbody/tr[${i}]/td[1]/span    innerHTML
            #Se ve si el valor de la cerlda es igual al nombre de la evaluacion actual
            ${iguales}    Strings Should Be Equal    ${evaluacionTabla}    ${evaluacion}
            #Si son iguales
            IF    ${iguales}
                #Selecciona la evaluacion y se ingresa a la zona de ingreso de notas
                Click Element    //*[@id="tbl-evaluaciones"]/tbody/tr[${i}]/td[12]/a
                Wait Until Page Contains Element    //*[@id="observaciones"]
                #Ingresa las notas de los estudiantes de la evaluacion definida
                Ingresar Notas    ${evaluacion}
                CONTINUE
            END
        #Sale del ciclo si la celda i ya no pertenece a la tabla
        ELSE IF    ${esEvaluacion} == False and ${existeEnLaTabla} == False
            BREAK
        ELSE
            CONTINUE
        END
    END
    
#Funcion que ingresa todas las notas en un archivo excel
Ingresar Todas las Notas
    #Abre el archivo excel
    Open Workbook    ${EXCEL}
    #Leer la hoja evaluaciones
    Set Active Worksheet    Evaluaciones
    ${archivoEvaluaciones}    Read Worksheet As Table    header=True
    Close Workbook
    FOR    ${evaluacion}    IN    @{archivoEvaluaciones}
        #Ingresar a cada evaluacion 
        Ingresar a Evaluacion y Colocar Notas    ${evaluacion}[Nombre]
    END

Volver a zona cursos
    Unselect Frame
    Unselect Frame
    Click Link    Mis Cursos
    Click Link    Listado Cursos

*** Tasks ***
Launch Browser
    Open the intranet website
    Iniciar Sesion en LOA
    Ir a Curso
    Ir a Zona Calificaciones
    Ingresar Todas las Notas
    Volver a zona cursos
    
