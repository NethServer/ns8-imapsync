*** Settings ***
Documentation     Coverage for the actions and helpers no other suite touches: the CSV
...               bulk import, the get-facts counters, the exclusion folder mode, the
...               generated cron file, stopping a running sync and the vmail master
...               secret. None of them was exercised before.
Library           SSHLibrary
Resource          imapsync.resource
Suite Setup       Retrieve the mail host
Suite Teardown    Delete every task

*** Variables ***
${csvfile}          /tmp/imapsync-import.csv
# TEST-NET-1 (RFC 5737): reserved for documentation, so the connect always hangs
${blackhole}        192.0.2.1

*** Keywords ***
Write CSV
    [Documentation]    The password holds a comma, so it must stay quoted in the CSV.
    [Arguments]    ${body}
    ${rc} =    Execute Command    printf '%s' '${body}' > ${csvfile}
    ...    return_rc=True    return_stdout=False
    Should Be Equal As Integers    ${rc}    0

Import the CSV
    ${out}    ${rc} =    Execute Command
    ...    runagent -m ${imapsync_module_id} import-csv-tasks < ${csvfile}
    ...    return_rc=True
    RETURN    ${out}    ${rc}

Module state file
    [Documentation]    Reads a file under the module state directory, resolved from
    ...                AGENT_STATE_DIR instead of a hardcoded /home path.
    [Arguments]    ${relative}
    ${out}    ${rc} =    Execute Command
    ...    runagent -m ${imapsync_module_id} sh -c 'cat "$AGENT_STATE_DIR/${relative}"'
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}    0    cannot read ${relative} in the module state
    RETURN    ${out}

*** Test Cases ***
Import two tasks from a CSV
    [Documentation]    import-csv-tasks reads the CSV on stdin, maps the six required
    ...                columns and generates the task id itself.
    ${count} =    Task count
    Should Be Equal As Integers    ${count}    0    the suite expects no leftover task
    Write CSV    localusername,remoteusername,remotepassword,remotehostname,remoteport,security\n${localuser},${remoteuser},"Nethesis,1234",${mail_host},143,tls\n${localuser},${remoteuser},"Nethesis,1234",${mail_host},993,ssl\n
    ${out}    ${rc} =    Import the CSV
    Should Be Equal As Integers    ${rc}    0    CSV import failed:\n${out}
    Should Contain    ${out}    2 successful
    ${count} =    Task count
    Should Be Equal As Integers    ${count}    2

Verify the generated task ids are get-log compatible
    [Documentation]    import-csv-tasks builds a random id; get-log rejects anything that
    ...                is not exactly six lowercase alphanumerics.
    ${result} =    Run task    module/${imapsync_module_id}/list-tasks    {}
    FOR    ${props}    IN    @{result['user_properties']}
        Should Match Regexp    ${props['task_id']}    ^[a-z0-9]{6}$
        ...    msg=generated id ${props['task_id']} would be rejected by get-log
    END

Verify the CSV columns and the auto-filled defaults
    [Documentation]    Also the only place where security "ssl" is exercised.
    ${result} =    Run task    module/${imapsync_module_id}/list-tasks    {}
    ${securities} =    Evaluate    sorted(p['security'] for p in $result['user_properties'])
    Should Be Equal    ${securities}    ${{ ['ssl', 'tls'] }}
    ${ports} =    Evaluate    sorted(int(p['remoteport']) for p in $result['user_properties'])
    Should Be Equal    ${ports}    ${{ [143, 993] }}
    FOR    ${props}    IN    @{result['user_properties']}
        Should Be Equal    ${props['localuser']}          ${localuser}
        Should Be Equal    ${props['remoteusername']}     ${remoteuser}
        Should Be Equal    ${props['foldersynchronization']}    all
        Should Be Equal    ${props['cron']}               ${EMPTY}
        Should Not Be True    ${props['delete_local']}
        Should Not Be True    ${props['delete_remote']}
        Should Not Be True    ${props['sieve_enabled']}
        Should Be Equal As Integers    ${props['delete_remote_older']}    0
    END
    [Teardown]    Delete every task

Reject a CSV missing a required column
    Write CSV    localusername,remoteusername,remotepassword,remotehostname,remoteport\n${localuser},${remoteuser},"Nethesis,1234",${mail_host},143\n
    ${out}    ${rc} =    Import the CSV
    Should Not Be Equal As Integers    ${rc}    0    a CSV without the security column must be refused
    Should Contain    ${out}    Missing
    ${count} =    Task count
    Should Be Equal As Integers    ${count}    0    a refused CSV must create nothing

Reject a CSV with a non-numeric port
    Write CSV    localusername,remoteusername,remotepassword,remotehostname,remoteport,security\n${localuser},${remoteuser},"Nethesis,1234",${mail_host},notaport,tls\n
    ${out}    ${rc} =    Import the CSV
    Should Not Be Equal As Integers    ${rc}    0    a non-numeric port must be refused
    Should Contain    ${out}    Invalid
    ${count} =    Task count
    Should Be Equal As Integers    ${count}    0    a refused CSV must create nothing
    [Teardown]    Execute Command    rm -f ${csvfile}

Count tasks by shape with get-facts
    [Documentation]    get-facts derives seven counters from the task env files. Three
    ...                tasks of known shapes pin every counter at once.
    Create sync task    facta1    inbox    true     false    0    cron=5m
    Create sync task    factb1    all     false    true     5
    Create sync task    factc1    inbox   false    true      0
    ${facts} =    Run task    module/${imapsync_module_id}/get-facts    {}
    Should Be Equal As Integers    ${facts['tasks_total_count']}             3
    Should Be Equal As Integers    ${facts['tasks_delete_count']}            2
    Should Be Equal As Integers    ${facts['tasks_delete_older_count']}      1
    Should Be Equal As Integers    ${facts['tasks_inbox_count']}             2
    Should Be Equal As Integers    ${facts['tasks_inbox_and_delete_count']}  1
    Should Be Equal As Integers    ${facts['tasks_cron_enabled_count']}      1
    Should Be Equal As Integers    ${facts['tasks_sieve_enabled_count']}     1

Verify the cron file generated for a scheduled task
    [Documentation]    A cron of "5m" must become a */5 schedule calling syncctl with
    ...                <localuser>_<task_id>, and MAIL_HOST must be carried over because
    ...                the cron environment is not the service one.
    ${cron} =    Module state file    cron/${localuser}_facta1.cron
    Should Contain    ${cron}    MAIL_HOST=${mail_host}
    Should Contain    ${cron}    */5 * * * * root /usr/local/bin/syncctl start ${localuser}_facta1

Exclude folders listed by the exclusion mode
    [Documentation]    foldersynchronization=exclusion is the only mode that builds
    ...                exclude_regex, turning the comma separated list into the pipe
    ...                separated alternation imapsync expects.
    Create sync task    exclu1    exclusion    false    false    0    exclude=Junk,Drafts
    ${props} =    Wait for a completed sync    exclu1
    Should Be Equal As Integers    ${props['last_sync_exit_code']}    0
    Should Be Equal    ${props['exclude']}    ,Junk,Drafts
    ${log} =    Read the task log    exclu1
    Should Contain    ${log}    Excluding folders matching pattern ^Shared(/.*)?$|^Public(/.*)?$|Junk|Drafts
    ...    msg=the comma separated exclude list did not become a pipe separated alternation
    [Teardown]    Delete sync task    exclu1

Verify the vmail master secret was fetched
    [Documentation]    reveal-master-secret asks the mail module for the vmail password and
    ...                writes it where syncctl reads it with --passfile2. Without it every
    ...                sync would fail to authenticate on host2.
    ${secret} =    Module state file    imapsync/vmail.pwd
    Should Not Be Empty    ${secret.strip()}

Stop a running sync without losing the last status
    [Documentation]    syncctl treats exit code 143 as a manual stop and must leave .status
    ...                alone, so a stopped run must not overwrite the previous result.
    Create sync task    stopt1
    ${first} =    Wait for a completed sync    stopt1
    # create-task validates the connection, so the host can only be pointed at TEST-NET-1
    # (RFC 5737) afterwards. The connect then hangs, giving a wide window to stop the sync.
    ${rc} =    Execute Command
    ...    runagent -m ${imapsync_module_id} sh -c 'sed -i "s/^REMOTEHOSTNAME=.*/REMOTEHOSTNAME=${blackhole}/" "$AGENT_STATE_DIR/imapsync/${localuser}_stopt1.env"'
    ...    return_rc=True    return_stdout=False
    Should Be Equal As Integers    ${rc}    0
    ${rc} =    Execute Command
    ...    api-cli run module/${imapsync_module_id}/start-task --data '{"localuser": "${localuser}","task_id": "stopt1"}'
    ...    return_rc=True    return_stdout=False
    Should Be Equal As Integers    ${rc}    0
    Wait until the task service is    stopt1    ${TRUE}
    ${rc} =    Execute Command
    ...    api-cli run module/${imapsync_module_id}/stop-task --data '{"localuser": "${localuser}","task_id": "stopt1"}'
    ...    return_rc=True    return_stdout=False
    Should Be Equal As Integers    ${rc}    0
    ${props} =    Wait until the task service is    stopt1    ${FALSE}
    Should Be Equal    ${props['last_sync_timestamp']}    ${first['last_sync_timestamp']}
    ...    msg=the manual stop overwrote the last sync status
    Should Be Equal    ${props['last_sync_exit_code']}    ${first['last_sync_exit_code']}
    ...    msg=the manual stop overwrote the last sync exit code

Stopping an already stopped task is harmless
    ${rc} =    Execute Command
    ...    api-cli run module/${imapsync_module_id}/stop-task --data '{"localuser": "${localuser}","task_id": "stopt1"}'
    ...    return_rc=True    return_stdout=False
    Should Be Equal As Integers    ${rc}    0
    [Teardown]    Delete sync task    stopt1
