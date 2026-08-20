*** Settings ***
Documentation     Keywords shared by the imapsync suites.
Library           SSHLibrary
Resource          api.resource

*** Variables ***
${localuser}        u2
${remoteuser}       u3
${maildomain}       domain.test

*** Keywords ***
Count messages
    [Documentation]    Messages matching ${query} in the INBOX of ${user}
    [Arguments]    ${user}    ${query}
    ${out}    ${rc} =    Execute Command
    ...    runagent -m ${MID} podman exec dovecot doveadm search -u ${user} mailbox INBOX ${query} | wc -l
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    ${count} =    Evaluate    int($out)
    RETURN    ${count}

Wait until message count is
    [Arguments]    ${user}    ${query}    ${expected}
    FOR    ${i}    IN RANGE    30
        ${count} =    Count messages    ${user}    ${query}
        IF    ${count} == ${expected}
            RETURN    ${count}
        END
        Sleep    2s
    END
    ${count} =    Count messages    ${user}    ${query}
    Should Be Equal As Integers    ${count}    ${expected}
    ...    msg=${user} INBOX "${query}": expected ${expected}, got ${count}
    RETURN    ${count}

Deliver messages to
    [Arguments]    ${user}    ${count}
    FOR    ${i}    IN RANGE    ${count}
        ${rc} =    Execute Command
        ...    MAIL_SERVER=smtp://127.0.0.1:10587 bash /tmp/test-msa.sh ${user}@${maildomain} u1@${maildomain}
        ...    return_rc=True    return_stdout=False
        Should Be Equal As Integers    ${rc}    0
    END

Create sync task
    [Documentation]    cron is empty by default: a periodic run would race with the
    ...                assertions on message counts.
    [Arguments]    ${task_id}    ${folders}=all    ${sieve}=false    ${delete_remote}=false
    ...            ${older}=0    ${cron}=${EMPTY}    ${exclude}=${EMPTY}
    ...            ${security}=tls    ${port}=143
    ${rc} =    Execute Command
    ...    api-cli run module/${imapsync_module_id}/create-task --data '{"cron": "${cron}","delete_local": false,"delete_remote": ${delete_remote},"delete_remote_older": ${older},"exclude": "${exclude}","foldersynchronization": "${folders}","localuser": "${localuser}","remotehostname": "${mail_host}","remotepassword": "Nethesis,1234","remoteport": ${port},"remoteusername": "${remoteuser}","security": "${security}","task_id": "${task_id}"}'
    ...    return_rc=True    return_stdout=False
    Should Be Equal As Integers    ${rc}    0

Delete sync task
    [Arguments]    ${task_id}
    ${rc} =    Execute Command
    ...    api-cli run module/${imapsync_module_id}/delete-task --data '{"localuser": "${localuser}","task_id": "${task_id}"}'
    ...    return_rc=True    return_stdout=False
    Should Be Equal As Integers    ${rc}    0

Delete every task
    [Documentation]    Leaves list-tasks empty whatever the suite created.
    ${result} =    Run task    module/${imapsync_module_id}/list-tasks    {}
    FOR    ${props}    IN    @{result['user_properties']}
        ${rc} =    Execute Command
        ...    api-cli run module/${imapsync_module_id}/delete-task --data '{"localuser": "${props['localuser']}","task_id": "${props['task_id']}"}'
        ...    return_rc=True    return_stdout=False
        Should Be Equal As Integers    ${rc}    0
    END

Task count
    ${result} =    Run task    module/${imapsync_module_id}/list-tasks    {}
    ${count} =    Get Length    ${result['user_properties']}
    RETURN    ${count}

Task properties
    [Arguments]    ${task_id}
    ${result} =    Run task    module/${imapsync_module_id}/list-tasks    {}
    FOR    ${props}    IN    @{result['user_properties']}
        IF    '${props['task_id']}' == '${task_id}'
            RETURN    ${props}
        END
    END
    Fail    task ${task_id} is missing from list-tasks

Wait for a completed sync
    [Documentation]    syncctl writes the .status file only once imapsync has exited, so a
    ...                timestamp newer than ${after} means the run is over.
    [Arguments]    ${task_id}    ${after}=${0}
    FOR    ${i}    IN RANGE    60
        ${props} =    Task properties    ${task_id}
        ${ts} =    Set Variable    ${props['last_sync_timestamp']}
        IF    $ts is not None and int($ts) > int($after)
            RETURN    ${props}
        END
        Sleep    2s
    END
    Fail    sync of ${task_id} did not complete within 120s

Read the task log
    [Arguments]    ${task_id}
    ${result} =    Run task    module/${imapsync_module_id}/get-log
    ...    {"task_id": "${task_id}", "localuser": "${localuser}"}
    Should Not Be Empty    ${result['log_content']}
    RETURN    ${result['log_content']}

Verify imapsync accepted every option
    [Documentation]    imapsync answers an unknown option with "Found N supplementary
    ...                arguments" followed by "misspelled or unknown options". That is the
    ...                exact signature of a local patch no longer applying.
    [Arguments]    ${task_id}
    ${log} =    Read the task log    ${task_id}
    Should Not Contain    ${log}    supplementary arguments
    ...    msg=imapsync rejected an option of task ${task_id}: a local patch no longer applies
    Should Not Contain    ${log}    misspelled or unknown options
    ...    msg=imapsync rejected an option of task ${task_id}: a local patch no longer applies

Retrieve the mail host
    [Documentation]    mail_modules_value is only a suite variable of 20_imapsync.robot, so
    ...                each suite reads the configured host back from get-configuration.
    ${ocfg} =    Run task    module/${imapsync_module_id}/get-configuration    {}
    Should Not Be Empty    ${ocfg['mail_host']}
    Set Suite Variable    ${mail_host}    ${ocfg['mail_host']}
