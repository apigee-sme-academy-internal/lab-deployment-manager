# Lab Deployment Manager

This repo has the configuration for a Qwiklabs deployment manager that can be re-used across
multiple labs. 

## How it works

The idea is that you create a lab in a separate git repo, and this deployment
manager will clone your lab's repo, and then run a startup script.

The deployment manager expects your lab to contain a script called `startup.sh` at the top level.

## How to build it

To build the deployment manager, run the script:
```shell script
./build.sh LAB_REPO LAB_BRANCH
```

e.g.
```shell script
./build.sh git@github.com:apigee-sme-academy-internal/app-modernization-lab-2.git master 
```

This creates a zip file called `deployment-manager.zip` within the `./build` output directory.

If your lab requires a private key to clone the lab's repo, you need provide the private key to the build script:

```shell script
build.sh LAB_REPO LAB_BRANCH ./path/to/private.key
```

e.g.
```shell script
./build.sh git@github.com:apigee-sme-academy-internal/app-modernization-lab-2.git master ~/deploy-keys/lab2
```

If you do not provide a private key, then an ephemeral key gets generated during the build process.

## Building Deployment Manager for Apigee SME Academy labs

The Apigee SME Academy labs are hosted in an internal git repo. While there is no sensitive
data stored in any of the repos, we do not want to publicly expose the assets there. However,
these assets need to be available to the Qwiklabs automation. 

In order to bridge this gap, we created a bot/automation account in Github. 
This account is [apigeesmeacademy-automation](https://github.com/apigeesmeacademy-automation).
This user account has been added to each of the labs with `read-only` access.

When the deployment manager runs inside a Qwiklabs project, it will try to clone your lab's repo. 
This is where the automation account comes in. For the deployment manager to be able to clone the repo,
you must build the `deployment-manager.zip` file using the private key for the automation user. To do this, follow the examples below:

* Login to GCP using gcloud
```shell script
gcloud auth login
```

* Set the Apigee SME Academy Project
```shell script
gcloud config set project apigee-sme-academy
```

* Download the private key for the automation user
```shell script
gcloud secrets versions access latest --secret=automation-deploy-key > ~/deployment.pem
```

* Finally, build the deployment manager zip file
```shell script
./build.sh git@github.com:apigee-sme-academy-internal/app-modernization-lab-2.git master ~/deployment.pem
```


### How to use it

To use the deployment manager, you have to go on the Qwiklabs UI, and edit your lab.

<p align="center">
  <img src="images/qwiklabs-deployment-manager_add_zip.png" width="400px" />
</p>

In the main lab settings, click on the deployment manager section, and upload the `deployment-manager.zip` file.


### Environment

When your lab's `startup.sh` script runs, the deployment manager has already setup a few things in the
environment to make things easy for you. 

The following tools/scripts are made available in the path:

* **rewind.sh** - for creating an Apigee Hybrid Cluster
* **git** - for cloning other repos
* **jq** - for parsing and extracting data from JSON files)
* **gcloud** - already logged in, full access to the GCP project
* **node** - v12, for running your own Node.js scripts
* **kubectl** - for accessing gke clusters
* **mvn** - v3, for deploying Apigee proxies
* **java** - v11, for use by maven

The following environment variables are available:

* **$LAB_DIR** - Directory for your lab
* **$ZONE** - Zone for the GCP project
* **$REGION** - Region for the GCP project
* **$PROJECT** - Name of the GCP project
* **$QWIKLAB_USER** - Username for the qwiklab student
* **$QWIKLAB_PASSWORD** - Password for the qwiklab student
* **$SERVICE_ACCOUNT_JSON** - JSON string for the Qwiklab user service account
* **$ASSETS_SERVICE_ACCOUNT_JSON** - JSON string for the SME Academy automation user service account 
* **$RUNTIME_HOST_ALIAS** - Hostname for the Apigee hyrbdi runtime (e.g. api.qwiklabs-gcp-00-a97f7ffba65e.apigeelabs.com)
* **$MART_HOST_ALIAS** - Hostname for the Apigee hybrid MART (e.g. mart.qwiklabs-gcp-00-a97f7ffba65e.apigeelabs.com)
* **$PORTAL_HOST_ALIAS** - Hostname for the developer portal (e.g. developer.qwiklabs-gcp-00-a97f7ffba65e.apigeelabs.com)


Also, the deployment manager creates a storage with the same name as the project.
The bucket is publicly accessible by everyone. The idea is that, as part
of your lab, if there are any assets that the student needs, you should be able to do
this in your lab's startup script:

```shell script
source ~/env
# Upload the assets directory
gsutil -m cp -R assets gs://${PROJECT}
```

That way in your lab instructions, you can point the student to the assets in the bucket.



