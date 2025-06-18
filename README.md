## Local Setup
### Prerequisites:
* ***Docker*** and ***Docker Compose*** installed on your machine

### Setup

1. **Clone the source code to your working-directory**

2.  **Set environement variables**
    * Create a copy of ***.env.exemple*** named ***.env***. 
        > In it, you can set your own values of course, as long as they are consistent with the rest of the following config.\
        > The <mark>DOMAIN_NAME</mark> value in particular

3.  **Bind your DOMAIN_NAME to the localhost:**
    * Add these two lines to the `hosts` file: `C:\Windows\System32\drivers\etc\hosts` (on Windows) and `/etc/hosts` (on Linux).

        ```
        127.0.0.1 <local-domain-name>
        127.0.0.1 <dashboard-prefix>.<local-domain-name>
        ```
    * For example:

        ```
        127.0.0.1 my-local-domain.com
        127.0.0.1 my-dashboard-prefix.my-local-domain.com
        ```

4.  **Create the common (external) network which will be used by all services managed by Traefik:**
    * Open a terminal and type in:
        ```shell
        docker network create my-external-network
        ```

5.  **Launch the services using docker compose:**
    * In your terminal, first ***cd*** to your working-directory then type:
        ```shell
        docker compose -f docker-compose.yaml -f docker-compose.local.yaml up
        ```
---

### Testing
* Check that both the ***traefik-reverse-proxy*** and ***traefik-mkcert*** containers are running and healthy.
* Check your ***certs*** directory, if eveything went fine, it should now be populated with local certificates.
If you check in the logs (here I am using Docker Desktop) you should have this:
![Docker Desktop mkcert logs](images/mkcert-container-log.png)  <br>

* Open the following address in your browser: ***http://localhost:8080/dashboard/***\
You should be seeing the following dashboard:
![Traefik Dashboard](images/traefik-dashboard.png)
 
---

## Deploy on a Real Domain
### Prerequisites:
- SSH access to a deployment/hosting server
- A registered domain name
- ***Docker*** and ***Docker Compose*** installed on your deployment/hosting server

---

### Setup
> From now on, everything that follows (commands/instructions) will of course assume you are on a terminal connected to your remote server through SSH
* **Optional:** Secure the dashboard access using a *BasicAuth* authentication (you need to have **htpasswd** installed)

    * Generate the **TRAEFIK_CREDENTIALS**
        ```shell
        echo $(htpasswd -nb <your-username> <your-pwd>) | sed -e s/\\$/\\$\\$/g
        ```
    * Remember/save the values you entered for the **\<your-username\>** and **\<your-pwd\>** as they wil be the values needed to access your dashboard respectively for the username and password.

1. **Clone (or remote copy) the source code to your server's working-directory of choice**

2.  **Set environement variables:**
    * Create a copy of ***.env.exemple*** named ***.env*** and set the correct values within it:
        * **ENV**=prod.
        * Your own **DOMAIN_NAME**
        * Your own **DASHBOARD_PREFIX**
        * If applicable, the previously generated value for **TRAEFIK_CREDENTIALS**

3.  **Create the common (external) network which will be used by all services managed by Traefik:**
    * In your ssh terminal, type in:
        ```shell
        docker network create my-external-network
        ```
4. **Set your own contact email**
    ```yaml {title=docker-compose.prod.yaml linenos=inline hl_lines=["9"] lineNoStart=64}
      ##############################################################################################
      # tlschallenge challenge
      ##############################################################################################
      # Email address used for registration.
      #
      # Required
      #
      #- "--certificatesresolvers.tlsResolver.acme.email=/secrets/cert_contact_email"
      - "--certificatesresolvers.tlsResolver.acme.email=contact@my-domain.com"
    ```
    > This email should be a real one, you cannot use a fake one even for the staging servers 

5. **Set the TLS certificate servers**
    > In order to avoid exceeding the rate limit set on Let's Encrypt production servers, it is advisable to first try out and make all your tests using the Let's Encrypt staging servers:
    ```yaml {title=docker-compose.prod.yaml linenos=inline hl_lines=["9"] lineNoStart=80}
      # CA server to use.
      # Uncomment the line to use Let's Encrypt's staging server,
      # leave commented to go to prod.
      #
      # Optional
      # Default: "https://acme-v02.api.letsencrypt.org/directory"
      # Staging: "https://acme-staging-v02.api.letsencrypt.org/directory"
      #
      - "--certificatesresolvers.tlsResolver.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
    ```

6.  **Prepare your Traefik dashboard access subdomain:**
    * Go to your domain provider **DNS zone** and add a **CNAME** entry which will be the Traefik dashboard
    * For example, if your domain name is "***my-domain-name.com***" and the **DASHBOARD_PREFIX** is  "***my-traefik-dashboard***", you need to add "***my-traefik-dashboard.my-domain-name.com***" as a **CNAME** and point it to "***my-domain-name.com***"

7.  **Launch Traefik in production:**
    * In your terminal, first ***cd*** to your working-directory then type:
        ```shell
        docker compose -f docker-compose.yaml -f docker-compose.prod.yaml up
        ```

#### Important!
> Be aware that the staging server's configuration will emit valid certificates, however not trusted by your browsers. When accessing your domain (and subdomains), you will have a warning ***NET::ERR_CERT_AUTHORITY_INVALID***  that you'd need to bypass in order to accept the certificates as trusted ones.
    
* Once everything is tested out and in full order using the staging servers, put back the production servers url (Default): "https://acme-v02.api.letsencrypt.org/directory"

---

### Testing
* Check that the ***traefik-reverse-proxy*** container is running and healthy.
* Access your dashboard at: ***https://my-traefik-dashboard.my-domain-name.com/dashboard/*** (of course replace with your own real subdomain address)
    > If you've set the BasicAuth, you'd of course need to provide your username/password set previously in order to be authenticated
* Check the ***acme.json*** file
    * ssh to your server and access your reverse proxy container:
    ```shell
    docker exec -it prod-traefik-reverse-proxy sh
    ```
    * Now, if you open the ***acme.json*** file, it should have the certificates for both your main domain and your subdomain (Traefik dashboard):
    ```shell
    cat /letsencrypt/acme.json
    ```