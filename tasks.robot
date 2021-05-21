*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
...               Author: Juan Camilo Hernández - 2021
Library     RPA.Tables
Library     RPA.HTTP
Library     RPA.Browser.Selenium
Library     RPA.PDF
Library     RPA.FileSystem
Library     RPA.Archive
Library     RPA.RobotLogListener
Library     RPA.Dialogs
Library     RPA.Robocloud.Secrets


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${csv_url}=    Ask for CSV URL
    Donwnload CSV   ${csv_url}
    ${credentials}=    Get Secret    credentials
    Go to Website   ${credentials}[website]
    ${Orders}=    Read table from CSV    input/orders.csv
    FOR    ${order}    IN    @{orders}
    	Manage Modal
        Fill Form   ${order}
        Preview Robot
        Wait Until Keyword Succeeds    5x    0.5 sec    Store Receipt as PDF    ${order}
        New Order
    END
    ZIP Receipts


*** Keywords ***
Ask for CSV URL
    Add heading         CSV Location
    Add text input      url    label=URL
    &{result}=    Run dialog
    [Return]    ${result["url"]}

Donwnload CSV
    [Arguments]    ${csv_url}
    Download    ${csv_url}  overwrite=True  target_file=input

Go to Website
    [Arguments]    ${url}
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Manage Modal
    Click Element If Visible    css:button.btn-dark

Fill Form
    [Arguments]    ${order}
    Wait Until Element Is Visible   //*[@id="head"]     timeout=15
    Select From List By Value       //*[@id="head"]     ${order}[Head]
    Click Element                   //*[@id="id-body-${order}[Body]"]
    Input Text                      css=input[placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text                      //*[@id="address"]    ${order}[Address]

Preview Robot
    Click Button   //*[@id="preview"]
    Wait Until Element Is Visible      //*[@id="robot-preview-image"]

Store Receipt as PDF
    [Arguments]    ${order}
    Click Element   //*[@id="order"]
    Wait Until Element Is Visible      //*[@id="receipt"]       timeout=3
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUTDIR}${/}receipts${/}${order}[Order number]-details.pdf
    Wait Until Element Is Visible       css:#robot-preview-image img[alt=Head]
    Wait Until Element Is Visible       css:#robot-preview-image img[alt=Body]
    Wait Until Element Is Visible       css:#robot-preview-image img[alt=Legs]
    Capture Element Screenshot      //*[@id="robot-preview-image"]      ${OUTPUTDIR}${/}receipts${/}robot_image.png
    ${files}=    Create List
    ...    ${OUTPUTDIR}${/}receipts${/}${order}[Order number]-details.pdf
    ...    ${OUTPUTDIR}${/}receipts${/}robot_image.png
    Add Files To PDF    ${files}    ${OUTPUTDIR}${/}receipts${/}${order}[Order number].pdf
    Remove File    ${OUTPUTDIR}${/}receipts${/}${order}[Order number]-details.pdf
    Remove File    ${OUTPUTDIR}${/}receipts${/}robot_image.png 

New Order
    Click Element       //*[@id="order-another"]

ZIP Receipts
    Archive Folder With Zip     ${OUTPUTDIR}${/}receipts    ${OUTPUTDIR}${/}receipts.zip
    Remove Directory            ${OUTPUTDIR}${/}receipts    True