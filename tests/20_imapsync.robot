*** Settings ***
Library    SSHLibrary
Resource    api.resource

*** Test Cases ***
Check if imapsync is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Global Variable    ${imapsync_module_id}    ${output.module_id}

Check if we can retrieve the mail module ID
    FOR    ${i}    IN RANGE    30
        ${ocfg} =   Run task    module/${imapsync_module_id}/get-configuration    {}
        Log    ${ocfg}
        Run Keyword If    ${ocfg}    Exit For Loop
        Sleep    2s
    END
    Set Suite Variable     ${mail_modules_value}    ${ocfg['mail_server_URL'][0]['value']}
    Should Not Be Empty    ${mail_modules_value}

Check if imapsync can be configured
    ${mail_server_uuid}    ${mail_server_ip}=    Evaluate    "${mail_modules_value}".split(",")
    ${rc} =    Execute Command    api-cli run module/${imapsync_module_id}/configure-module --data '{"mail_host": "${mail_server_ip}","mail_server": "${mail_server_uuid}"}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Send 5 emails to the mail server: from u1 to u3
    Put File    ${CURDIR}/test-msa.sh    /tmp/test-msa.sh
    ${mail_server} =    Set Variable    smtp://127.0.0.1:10587
    ${from} =    Set Variable    u1@domain.test
    ${to} =    Set Variable    u3@domain.test
    FOR    ${i}    IN RANGE    5
        ${out}  ${err}  ${rc} =    Execute Command
        ...    MAIL_SERVER=${mail_server} bash /tmp/test-msa.sh ${to} ${from}
        ...    return_rc=True    return_stderr=True
        Log    Mail helper stdout: ${out}
        Log    Mail helper stderr: ${err}
        Should Be Equal As Integers    ${rc}  0
    END

Check if imapsync can create a task to fetch emails from u3 to U2
    ${mail_server_uuid}    ${mail_server_ip}=    Evaluate    "${mail_modules_value}".split(",")
    ${rc} =    Execute Command    api-cli run module/${imapsync_module_id}/create-task --data '{"cron": "5m","delete_local": false,"delete_remote": true,"delete_remote_older": 0,"exclude": "","foldersynchronization": "all","localuser": "u2","remotehostname": "${mail_server_ip}","remotepassword": "Nethesis,1234","remoteport": 143,"remoteusername": "u3","security": "tls","sieve_enabled": false,"task_id": "28ofi1"}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Verify if imapsync has distributed the 5 emails to u2
    ${success} =    Set Variable    False
    FOR    ${i}    IN RANGE    5
        ${dovecot_out}    ${dovecot_err}    ${dovecot_rc} =    Execute Command
        ...    runagent -m ${MID} podman exec dovecot ls u2/Maildir/cur | wc -l
        ...    return_rc=True    return_stdout=True    return_stderr=True

        Should Be Equal As Integers    ${dovecot_rc}    0

        ${dovecot_clean} =    Evaluate    str(${dovecot_out}).strip()
        Log    Tentative ${i}: rcvd=${dovecot_clean}

        Run Keyword If    int(${dovecot_clean}) == 5    Set Test Variable    ${success}    True
        Run Keyword If    ${success}    Exit For Loop
        Sleep    1s
    END
    Should Be True    ${success}    the counter is equal to 5 emails received

Verify if imapsync has removed the 5 emails to u3
    ${success} =    Set Variable    False
    FOR    ${i}    IN RANGE    5
        ${dovecot_out}    ${dovecot_err}    ${dovecot_rc} =    Execute Command
        ...    runagent -m ${MID} podman exec dovecot ls u3/Maildir/cur | wc -l
        ...    return_rc=True    return_stdout=True    return_stderr=True

        Should Be Equal As Integers    ${dovecot_rc}    0

        ${dovecot_clean} =    Evaluate    str(${dovecot_out}).strip()
        Log    Tentative ${i}: rcvd=${dovecot_clean}

        Run Keyword If    int(${dovecot_clean}) == 0    Set Test Variable    ${success}    True
        Run Keyword If    ${success}    Exit For Loop
        Sleep    1s
    END
    Should Be True    ${success}    the counter is equal to 0 emails

Check the imap folder informations of u2
    ${ocfg} =  Run task    module/${imapsync_module_id}/list-informations    {"localuser": "u2","task_id": "28ofi1"}
    # Check expected sync results
    Should Be Equal As Integers    ${ocfg['host1Folders']}    3
    Should Be Equal As Integers    ${ocfg['host1Messages']}   0
    Should Be Equal As Integers    ${ocfg['host1Sizes']}      0
    Should Be Equal As Integers    ${ocfg['host2Folders']}    3
    Should Be Equal As Integers    ${ocfg['host2Messages']}   5
    Should Be True    7000 <= int(${ocfg['host2Sizes']}) < 8000 # the value can change
    Should Be True                 ${ocfg['status']}

Check if imapsync can remove a task 
    ${mail_server_uuid}    ${mail_server_ip}=    Evaluate    "${mail_modules_value}".split(",")
    ${rc} =    Execute Command    api-cli run module/${imapsync_module_id}/delete-task --data '{"localuser": "u2","task_id": "28ofi1"}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
