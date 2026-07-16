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

check if we can retrieve get-configuration
    ${ocfg} =   Run task    module/${imapsync_module_id}/get-configuration    {}
    ${mail_server_uuid}    ${mail_server_ip}=    Evaluate    "${mail_modules_value}".split(",")
    Should Be Equal    ${ocfg['mail_host']}     ${mail_server_ip}
    Should Be Equal    ${ocfg['mail_server']}   ${mail_server_uuid}
    Should Not Be Empty    ${ocfg['mail_server_URL'][0]['value']}

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

Verify list-tasks returns what create-task sent
    ${ocfg}=    Run task    module/${imapsync_module_id}/list-tasks    {}
    ${props}=    Set Variable    ${ocfg['user_properties'][0]}
    Should Be Equal    ${props['cron']}    5m
    Should Not Be True    ${props['delete_local']}
    Should Be True    ${props['delete_remote']}
    Should Be Equal As Integers    ${props['delete_remote_older']}    0
    Should Be Equal    ${props['foldersynchronization']}    all
    Should Be Equal    ${props['localuser']}    u2
    Should Be Equal    ${props['remoteport']}    143
    Should Be Equal    ${props['remoteusername']}    u3
    Should Be Equal    ${props['security']}    tls
    Should Not Be True    ${props['sieve_enabled']}
    Should Be Equal    ${props['task_id']}    28ofi1

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

Verify list-tasks status fields after sync
    ${result} =    Run task    module/${imapsync_module_id}/list-tasks    {}
    ${props} =    Set Variable    ${result['user_properties'][0]}
    Should Not Be Equal    ${props['last_sync_timestamp']}    ${None}
    Should Be True    int(${props['last_sync_timestamp']}) > 0
    Should Be Equal As Integers    ${props['last_sync_exit_code']}    0
    Should Be True    ${props['has_log']}

Test get-log action returns log content after sync
    ${result} =    Run task    module/${imapsync_module_id}/get-log    {"task_id": "28ofi1", "localuser": "u2"}
    Should Not Be Empty    ${result['log_content']}
    Should Be Equal    ${result['truncated']}    ${False}

Create Public and Shared folders with subfolders on u3
    Execute Command    runagent -m ${MID} podman exec dovecot doveadm mailbox create -u u3 Public    return_rc=True
    Execute Command    runagent -m ${MID} podman exec dovecot doveadm mailbox create -u u3 Public/Junk    return_rc=True
    Execute Command    runagent -m ${MID} podman exec dovecot doveadm mailbox create -u u3 Shared    return_rc=True
    Execute Command    runagent -m ${MID} podman exec dovecot doveadm mailbox create -u u3 Shared/estero    return_rc=True
    Execute Command    runagent -m ${MID} podman exec dovecot doveadm mailbox create -u u3 Shared/estero/Archive/2020    return_rc=True

Check if imapsync excludes Public and Shared subfolders
    ${mail_server_uuid}    ${mail_server_ip}=    Evaluate    "${mail_modules_value}".split(",")
    ${rc} =    Execute Command    api-cli run module/${imapsync_module_id}/create-task --data '{"cron": "5m","delete_local": false,"delete_remote": true,"delete_remote_older": 0,"exclude": "","foldersynchronization": "all","localuser": "u2","remotehostname": "${mail_server_ip}","remotepassword": "Nethesis,1234","remoteport": 143,"remoteusername": "u3","security": "tls","sieve_enabled": false,"task_id": "public_shared_test"}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Verify Public and Shared folders were NOT synced to u2
    ${success} =    Set Variable    False
    FOR    ${i}    IN RANGE    10
        ${dovecot_out}    ${dovecot_err}    ${dovecot_rc} =    Execute Command
        ...    runagent -m ${MID} bash -c "podman exec dovecot ls u2/Maildir 2>/dev/null | grep -E '^Public|^Shared' | wc -l"
        ...    return_rc=True    return_stdout=True    return_stderr=True
        Should Be Equal As Integers    ${dovecot_rc}    0
        ${dovecot_clean} =    Evaluate    "${dovecot_out}".strip()
        Log    Attempt ${i}: found=${dovecot_clean}
        Run Keyword If    '${dovecot_clean}' == '0'    Set Test Variable    ${success}    True
        Run Keyword If    ${success}    Exit For Loop
        Sleep    1s
    END
    Should Be True    ${success}    Public and Shared folders should NOT be synced

Verify no permission errors in imapsync logs
    ${log_out}    ${log_err}    ${log_rc} =    Execute Command
    ...    runagent -m ${MID} bash -c "podman exec imapsync grep -i 'NOPERM|Could not select' /etc/imapsync/public_shared_test.log && echo FOUND || echo OK"
    ...    return_rc=True    return_stdout=True    return_stderr=True
    Should Be Equal As Integers    ${log_rc}    0
    ${log_clean} =    Evaluate    "${log_out}".strip()
    Should Be Equal    ${log_clean}    OK    No permission errors should occur

Delete public_shared_test task
    ${rc} =    Execute Command    api-cli run module/${imapsync_module_id}/delete-task --data '{"localuser": "u2","task_id": "public_shared_test"}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if imapsync can remove a task
    ${mail_server_uuid}    ${mail_server_ip}=    Evaluate    "${mail_modules_value}".split(",")
    ${rc} =    Execute Command    api-cli run module/${imapsync_module_id}/delete-task --data '{"localuser": "u2","task_id": "28ofi1"}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Verify list-tasks is empty after delete-task
    ${ocfg}=    Run task    module/${imapsync_module_id}/list-tasks    {}
    Log    ${ocfg}    DEBUG
    Should Be Empty    ${ocfg['user_properties']}

Test get-log action returns empty log for non-existent task
    ${result} =    Run task    module/${imapsync_module_id}/get-log    {"task_id": "000000", "localuser": "u2"}
    Should Be Equal As Strings    ${result['log_content']}    ${EMPTY}
    Should Be Equal    ${result['truncated']}    ${False}

Test get-log action rejects invalid task_id format
    Run Keyword And Expect Error    *Validation errors*    Run task    module/${imapsync_module_id}/get-log    {"task_id": "invalid_task", "localuser": "u2"}

Test get-log action rejects path traversal in task_id
    Run Keyword And Expect Error    *Validation errors*    Run task    module/${imapsync_module_id}/get-log    {"task_id": "../etc", "localuser": "u2"}

Test get-log action rejects invalid localuser format
    Run Keyword And Expect Error    *Validation errors*    Run task    module/${imapsync_module_id}/get-log    {"task_id": "28ofi1", "localuser": "invalid@user"}

Test get-log action truncates log larger than 100KB
    [Documentation]    Create a 200KB log file, verify get-log returns at most 100KB and truncated=True
    ${logfile} =    Set Variable    /home/${imapsync_module_id}/.config/state/imapsync/u2_trunc1.log
    Execute Command    python3 -c "open('${logfile}', 'w').write('x\\n' * 102400)"
    ${result} =    Run task    module/${imapsync_module_id}/get-log    {"task_id": "trunc1", "localuser": "u2"}
    Should Be Equal    ${result['truncated']}    ${True}
    ${content_len} =    Get Length    ${result['log_content']}
    Should Be True    ${content_len} > 0
    Should Be True    ${content_len} <= 102400
    [Teardown]    Execute Command    rm -f ${logfile}

Test list-tasks status fields populated after task creation
    [Documentation]    create-task triggers an immediate sync via run-imapsync restart, so status fields must be populated
    ${rc} =    Execute Command    api-cli run module/${imapsync_module_id}/create-task --data '{"cron": "5m","delete_local": false,"delete_remote": false,"delete_remote_older": 0,"exclude": "","foldersynchronization": "all","localuser": "u2","remotehostname": "127.0.0.1","remotepassword": "Nethesis,1234","remoteport": 143,"remoteusername": "u3","security": "tls","sieve_enabled": false,"task_id": "status1"}'
    ...    return_rc=True    return_stdout=False
    Should Be Equal As Integers    ${rc}    0
    ${result} =    Run task    module/${imapsync_module_id}/list-tasks    {}
    ${props} =    Set Variable    ${result['user_properties'][0]}
    Should Not Be Equal    ${props['last_sync_timestamp']}    ${None}
    Should Be True    int(${props['last_sync_timestamp']}) > 0
    Should Not Be Equal    ${props['last_sync_exit_code']}    ${None}
    Should Be True    ${props['has_log']}
    [Teardown]    Execute Command    api-cli run module/${imapsync_module_id}/delete-task --data '{"task_id": "status1", "localuser": "u2"}'

Cron sync must not reset the Seen flag (NethServer/dev#8107)
    [Documentation]    On a cron task imapsync must run with --noresyncflags, so a message
    ...    marked Seen locally is not reset to Unseen by the untouched source on the next sync.
    ...    Uses foldersynchronization=all (folder_inbox empty), so --search1=UNSEEN/--setflag1=Seen
    ...    is NOT active and --noresyncflags is the only variable under test.
    ${mail_server_uuid}    ${mail_server_ip}=    Evaluate    "${mail_modules_value}".split(",")
    # Send 3 fresh emails u1 -> u3 (test-msa.sh already uploaded earlier in the suite)
    ${mail_server} =    Set Variable    smtp://127.0.0.1:10587
    FOR    ${i}    IN RANGE    3
        ${out}    ${err}    ${rc} =    Execute Command
        ...    MAIL_SERVER=${mail_server} bash /tmp/test-msa.sh u3@domain.test u1@domain.test
        ...    return_rc=True    return_stderr=True
        Should Be Equal As Integers    ${rc}    0
    END
    # Baseline: u2 INBOX may already hold messages from earlier tests
    ${base}    ${e}    ${c} =    Execute Command
    ...    runagent -m ${MID} podman exec dovecot doveadm search -u u2 mailbox INBOX all | wc -l
    ...    return_rc=True    return_stdout=True    return_stderr=True
    Should Be Equal As Integers    ${c}    0
    ${expected} =    Evaluate    int("${base}".strip()) + 3
    # Create cron task u3 -> u2, keep both sides (immediate sync fires on create)
    ${rc} =    Execute Command    api-cli run module/${imapsync_module_id}/create-task --data '{"cron": "5m","delete_local": false,"delete_remote": false,"delete_remote_older": 0,"exclude": "","foldersynchronization": "all","localuser": "u2","remotehostname": "${mail_server_ip}","remotepassword": "Nethesis,1234","remoteport": 143,"remoteusername": "u3","security": "tls","sieve_enabled": false,"task_id": "flagtest"}'
    ...    return_rc=True    return_stdout=False
    Should Be Equal As Integers    ${rc}    0
    # Wait until the 3 new messages land in u2 INBOX
    ${success} =    Set Variable    False
    FOR    ${i}    IN RANGE    15
        ${cnt}    ${e}    ${c} =    Execute Command
        ...    runagent -m ${MID} podman exec dovecot doveadm search -u u2 mailbox INBOX all | wc -l
        ...    return_rc=True    return_stdout=True    return_stderr=True
        Should Be Equal As Integers    ${c}    0
        ${cnt} =    Evaluate    "${cnt}".strip()
        Run Keyword If    int(${cnt}) >= ${expected}    Set Test Variable    ${success}    True
        Run Keyword If    ${success}    Exit For Loop
        Sleep    1s
    END
    Should Be True    ${success}    u2 should receive the 3 emails before the flag test
    # Mark every u2 message as Seen
    ${o}    ${e}    ${c} =    Execute Command
    ...    runagent -m ${MID} podman exec dovecot doveadm flags add -u u2 '\\Seen' mailbox INBOX all
    ...    return_rc=True    return_stdout=True    return_stderr=True
    Should Be Equal As Integers    ${c}    0
    # Precondition: no unseen message left on u2
    ${unseen}    ${e}    ${c} =    Execute Command
    ...    runagent -m ${MID} podman exec dovecot doveadm search -u u2 mailbox INBOX unseen | wc -l
    ...    return_rc=True    return_stdout=True    return_stderr=True
    ${unseen} =    Evaluate    "${unseen}".strip()
    Should Be Equal As Integers    ${unseen}    0    u2 messages should all be Seen before resync
    # Source u3 messages are still Unseen (never read) -> the overwrite condition exists
    ${src}    ${e}    ${c} =    Execute Command
    ...    runagent -m ${MID} podman exec dovecot doveadm search -u u3 mailbox INBOX unseen | wc -l
    ...    return_rc=True    return_stdout=True    return_stderr=True
    ${src} =    Evaluate    "${src}".strip()
    Should Be Equal As Integers    ${src}    3    source u3 must stay Unseen to test the resync overwrite
    # Re-run the sync synchronously (no -d) and re-check the flag
    ${o}    ${e}    ${c} =    Execute Command
    ...    runagent -m ${imapsync_module_id} podman exec imapsync /usr/local/bin/syncctl start u2_flagtest
    ...    return_rc=True    return_stdout=True    return_stderr=True
    Should Be Equal As Integers    ${c}    0
    ${unseen2}    ${e}    ${c} =    Execute Command
    ...    runagent -m ${MID} podman exec dovecot doveadm search -u u2 mailbox INBOX unseen | wc -l
    ...    return_rc=True    return_stdout=True    return_stderr=True
    ${unseen2} =    Evaluate    "${unseen2}".strip()
    Should Be Equal As Integers    ${unseen2}    0    --noresyncflags must preserve the Seen flag on cron resync
    # Negative control: a task WITHOUT cron gets no --noresyncflags, so it MUST overwrite the flag.
    # Only CRON differs from the task above -> proves --noresyncflags is what preserves the flag.
    # u2 still holds the 3 messages Seen and u3 still holds them Unseen, so the overwrite condition holds.
    ${rc} =    Execute Command    api-cli run module/${imapsync_module_id}/create-task --data '{"cron": "","delete_local": false,"delete_remote": false,"delete_remote_older": 0,"exclude": "","foldersynchronization": "all","localuser": "u2","remotehostname": "${mail_server_ip}","remotepassword": "Nethesis,1234","remoteport": 143,"remoteusername": "u3","security": "tls","sieve_enabled": false,"task_id": "flagctl"}'
    ...    return_rc=True    return_stdout=False
    Should Be Equal As Integers    ${rc}    0
    # create-task fired an immediate sync (run-imapsync restart); without --noresyncflags
    # the 3 synced messages are reset to Unseen from the untouched source.
    ${overwritten} =    Set Variable    False
    FOR    ${i}    IN RANGE    15
        ${u}    ${e}    ${c} =    Execute Command
        ...    runagent -m ${MID} podman exec dovecot doveadm search -u u2 mailbox INBOX unseen | wc -l
        ...    return_rc=True    return_stdout=True    return_stderr=True
        Should Be Equal As Integers    ${c}    0
        ${u} =    Evaluate    "${u}".strip()
        Run Keyword If    int(${u}) >= 3    Set Test Variable    ${overwritten}    True
        Run Keyword If    ${overwritten}    Exit For Loop
        Sleep    1s
    END
    Should Be True    ${overwritten}    a non-cron sync must overwrite the Seen flag (control proving --noresyncflags is the fix)
    [Teardown]    Run Keywords
    ...    Execute Command    api-cli run module/${imapsync_module_id}/delete-task --data '{"task_id": "flagtest", "localuser": "u2"}'
    ...    AND    Execute Command    api-cli run module/${imapsync_module_id}/delete-task --data '{"task_id": "flagctl", "localuser": "u2"}'
