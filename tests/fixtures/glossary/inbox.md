status: run
<!-- Steer this run from the GitHub app: edit this file on branch harness/dj-2026-10-17.
     Change the first line to "status: pause" or "status: stop"; write answers to questions under "## Answers".
     The harness pulls before every session; every session reads this file at startup. -->

### H3-02 (2026-10-17): before Gatus can be deployed (H3-04), set its two values
Gatus exits at start while either is empty, and agents can't check `/srv/docker/.env`, so H3-04 waits for this.
From the spec (step 1 of your one-time steps): pick a private ntfy topic. Put `GATUS_NTFY_TOPIC=<topic>` and a random
`GATUS_BACKUP_TOKEN=<token>` in `/srv/docker/.env`. Put `GATUS_BACKUP_URL=http://127.0.0.1:4590` and the same token in
`/etc/restic/env`. For example (`openssl rand -hex 24` makes a token; `deploy/.env.example` lists both names):

    nano /srv/docker/.env            # add GATUS_NTFY_TOPIC=… and GATUS_BACKUP_TOKEN=…
    sudoedit /etc/restic/env         # add GATUS_BACKUP_URL=http://127.0.0.1:4590 and GATUS_BACKUP_TOKEN=… (same token)

Then subscribe to the topic in the ntfy phone app. Write "gatus vars set" under Answers so H3-04 knows.


## Answers
