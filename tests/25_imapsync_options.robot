*** Settings ***
Documentation     Coverage for the three imapsync options that come from our local
...               patches: --setflag1, --sievedelivery2 and --delete1older.
...               20_imapsync.robot never exercises them, because every task it creates
...               uses foldersynchronization=all, sieve_enabled=false and
...               delete_remote_older=0. A patch silently failing to apply to a newer
...               imapsync release would therefore leave the suite green.
Library           SSHLibrary
Resource          api.resource
Suite Setup       Put File    ${CURDIR}/test-msa.sh    /tmp/test-msa.sh

*** Variables ***
${localuser}        u2
${remoteuser}       u3
${maildomain}       domain.test
# get-log validates task_id against ^[a-z0-9]{6}$
${setflagtask}      inbox1
${sievetask}        sieve1
${oldertask}        older1

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

Create task
    [Documentation]    cron is left empty on purpose: a periodic run would race with the
    ...                assertions on message counts.
    [Arguments]    ${task_id}    ${folders}    ${sieve}    ${delete_remote}    ${older}
    ${rc} =    Execute Command
    ...    api-cli run module/${imapsync_module_id}/create-task --data '{"cron": "","delete_local": false,"delete_remote": ${delete_remote},"delete_remote_older": ${older},"exclude": "","foldersynchronization": "${folders}","localuser": "${localuser}","remotehostname": "${mail_host}","remotepassword": "Nethesis,1234","remoteport": 143,"remoteusername": "${remoteuser}","security": "tls","sieve_enabled": ${sieve},"task_id": "${task_id}"}'
    ...    return_rc=True    return_stdout=False
    Should Be Equal As Integers    ${rc}    0

Delete task
    [Arguments]    ${task_id}
    ${rc} =    Execute Command
    ...    api-cli run module/${imapsync_module_id}/delete-task --data '{"localuser": "${localuser}","task_id": "${task_id}"}'
    ...    return_rc=True    return_stdout=False
    Should Be Equal As Integers    ${rc}    0

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

*** Test Cases ***
Retrieve the mail host used by imapsync tasks
    ${ocfg} =    Run task    module/${imapsync_module_id}/get-configuration    {}
    Should Not Be Empty    ${ocfg['mail_host']}
    Set Suite Variable    ${mail_host}    ${ocfg['mail_host']}

Deliver three unseen messages to the remote user
    ${unseen} =    Count messages    ${remoteuser}    unseen
    Set Suite Variable    ${remote_unseen_before}    ${unseen}
    ${local} =    Count messages    ${localuser}    all
    Set Suite Variable    ${local_total_before}    ${local}
    Deliver messages to    ${remoteuser}    3
    ${target} =    Evaluate    ${unseen} + 3
    Wait until message count is    ${remoteuser}    unseen    ${target}

Run an inbox-mode task so imapsync gets --setflag1
    [Documentation]    foldersynchronization=inbox makes syncctl add
    ...                --search1=UNSEEN --setflag1=Seen --noresyncflags
    Create task    ${setflagtask}    inbox    false    false    0
    ${props} =    Wait for a completed sync    ${setflagtask}
    Set Suite Variable    ${setflag_first_sync}    ${props['last_sync_timestamp']}
    Should Be Equal As Integers    ${props['last_sync_exit_code']}    0

Verify imapsync accepted --setflag1
    Verify imapsync accepted every option    ${setflagtask}

Verify --setflag1 flagged the remote messages as Seen
    [Documentation]    The transferred messages must now carry \\Seen on host1. Without the
    ...                setflag1 patch they would still be unseen.
    Wait until message count is    ${remoteuser}    unseen    ${remote_unseen_before}

Verify the messages reached the local user
    ${expected} =    Evaluate    ${local_total_before} + 3
    Wait until message count is    ${localuser}    all    ${expected}
    Set Suite Variable    ${local_total_after}    ${expected}

Verify a second run transfers nothing thanks to --search1=UNSEEN
    [Documentation]    This is the whole point of the setflag1 patch: messages already
    ...                transferred are Seen on host1, so --search1=UNSEEN skips them.
    # syncctl stamps .status with the run start time, so make sure the second run cannot
    # land on the same second as the first one.
    Sleep    1s
    ${rc} =    Execute Command
    ...    api-cli run module/${imapsync_module_id}/start-task --data '{"localuser": "${localuser}","task_id": "${setflagtask}"}'
    ...    return_rc=True    return_stdout=False
    Should Be Equal As Integers    ${rc}    0
    ${props} =    Wait for a completed sync    ${setflagtask}    ${setflag_first_sync}
    Should Be Equal As Integers    ${props['last_sync_exit_code']}    0
    ${count} =    Count messages    ${localuser}    all
    Should Be Equal As Integers    ${count}    ${local_total_after}
    ...    msg=the second run transferred messages again: --search1/--setflag1 is not effective
    [Teardown]    Delete task    ${setflagtask}

Run a task with retention so imapsync gets --delete1older
    [Documentation]    delete_remote with delete_remote_older>0 maps to --delete1older=N.
    ...                The messages are fresh, so nothing is expected to be removed: what
    ...                this checks is that imapsync accepts the patched option.
    Create task    ${oldertask}    all    false    true    5
    ${props} =    Wait for a completed sync    ${oldertask}
    Should Be Equal As Integers    ${props['last_sync_exit_code']}    0

Verify imapsync accepted --delete1older
    Verify imapsync accepted every option    ${oldertask}

Verify list-tasks reports the retention back
    [Documentation]    Also covers the --delete1older= parsing in list-tasks/20read
    ${props} =    Task properties    ${oldertask}
    Should Be True    ${props['delete_remote']}
    Should Be Equal As Integers    ${props['delete_remote_older']}    5
    [Teardown]    Delete task    ${oldertask}

Deliver two more unseen messages before the sieve task
    ${unseen} =    Count messages    ${remoteuser}    unseen
    Deliver messages to    ${remoteuser}    2
    ${target} =    Evaluate    ${unseen} + 2
    Wait until message count is    ${remoteuser}    unseen    ${target}

Run an inbox-mode task with sieve so imapsync gets --sievedelivery2
    [Documentation]    sieve_enabled alone is not enough: syncctl only honours it inside the
    ...                FOLDER_INBOX branch, hence foldersynchronization=inbox.
    Create task    ${sievetask}    inbox    true    false    0
    ${props} =    Wait for a completed sync    ${sievetask}
    Should Be Equal As Integers    ${props['last_sync_exit_code']}    0
    ...    msg=the sieve run failed; check that dovecot advertises the FILTER=SIEVE capability

Verify imapsync accepted --sievedelivery2
    Verify imapsync accepted every option    ${sievetask}

Verify the sievedelivery2 branch really ran
    [Documentation]    The patch prints this line just before issuing FILTER SIEVE DELIVERY,
    ...                so finding it proves the patched branch executed, not merely that the
    ...                option was accepted.
    ${log} =    Read the task log    ${sievetask}
    Should Contain    ${log}    FILTER SIEVE DELIVERY UID
    ...    msg=the sievedelivery2 branch did not run

Verify list-tasks reports sieve enabled
    ${props} =    Task properties    ${sievetask}
    Should Be True    ${props['sieve_enabled']}
    [Teardown]    Delete task    ${sievetask}

Verify no task is left behind
    ${result} =    Run task    module/${imapsync_module_id}/list-tasks    {}
    Should Be Empty    ${result['user_properties']}
