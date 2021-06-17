# Azure-Generate-Thumbnail-Blob-Upload-Trigger-Demo

The Blob storage trigger starts a function when a new or updated blob is detected. The blob contents are provided as input to the function.

The Azure Blob storage trigger requires a general-purpose storage account. Storage V2 accounts with hierarchical namespaces are also supported. To use a blob-only account, or if your application has specialized needs, review the alternatives to using this trigger.

# Table of Contents
1. [Overview](#overview)
2. [Cloning this Repository](#cloning-this-repository)
3. [Installing Dependencies](#installing-dependencies)
    1. [Terraform](#terraform)
    2. [Azure CLI](#azure-cli)
4. [Deploying to Azure](#deploying-to-azure)
    1. [Get Subscription and Tenant Id](#get-subscription-and-tenant-id)
    2. [Create and Configure a Service Pricipal](#create-and-configure-a-service-principal)
    4. [Update versions.tf File](#update-versions.tf-file)
    3. [Deploy Code](#deploy-code)
5. [Testing Functionality](#testing-functionality)
6. [Teardown](#teardown)

# Overview

With blob upload triggers you can leverage the advanced capabilities of Azure functions inside of your Azure blob storage. A common requirement is to shrink the size of an image after it is uploaded so it can be used in reports or returned to the app in a smaller size to reduce the bandwidth needed.

This repository contains code to deploy an example of how a blob trigger may be used to process images that are uploaded to a container hosted in an Azure stroage account and saved in another container after processing. The diagram below shows the infrastrucutre setup.

![](https://raw.githubusercontent.com/arun-mittal/azure-generate-thumbnail-blob-upload-trigger-demo/master/images/blob-upload-trigger-architecture.jpg)

# Cloning this Repository

To clone this repository, please follow the instructions on this [link](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/cloning-a-repository-from-github/cloning-a-repository).

For this to work, you will need to have git installed and the installation path configured as an environmental variable. If configured correctly, running `git --version` will return the version of git that you have installed.

# Installing Dependencies

There are 2 dependencies that need to be installed for the code to deploy successfully; Terraform and Azure CLI.

## Terraform

Terraform can be installed several ways and will vary based on your host operating system. Click [here](https://learn.hashicorp.com/tutorials/terraform/install-cli) to find a suitable method for you.

If installed correctly, running `terraform version` will return the version of Terraform installed on your system.

## Azure CLI

The Azure CLI can be installed for several operating systems. This [link](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) provides instructions for how to install the Azure CLI for the most common operating systems.

If installed correctly, running `az version` will return the version of Azure CLI installed on your system.

# Deploying to Azure

To authenticate with Azure, you will need your subscription and tenant id, client id and client secret.

## Get Subscription and Tenant Id

Login using the Azure CLI interface to the subscription where you want to deploy this solution.

```
az login
```
Get tenant and subscription Id.
```
az account list
```
Sample Response
```
[
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "isDefault": true,
    "managedByTenants": [],
    "name": "Account Name",
    "state": "Enabled",
    "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "user": {
      "name": "user@email.com",
      "type": "user"
    }
  }
}
```
In this response, the `id` is the subscription Id and `tenantId` is the tenant Id. Make a note of these as they will both be required. If you have several subscriptions listed, chose the one where you wish to deploy.

## Create and Configure a Service Principal

If you have already have a service principal created and know the client Id and client secret, you can skip this step. Otherwise follow the steps below to create one.

Run the create service principal command. You will need to substitute the \<service-principal-name\> with a name that that you wish to call your service principal and \<subscription-id\> with the subscrpition Id that you noted previously.

```
az ad sp create-for-rbac --name "<service-principal-name>" --role Contributor --scopes "/subscriptions/<Subscription-Id>"
```

Sample Response

```
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "myServicePrincipal",
  "name": "http://myServicePrincipal",
  "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```
Make a note of the `appId` and `password` as they will be required when deploying infrastructure using Terraform.

## Update versions&#46;tf File

The versions&#46;tf file needs to be updated to authenticate with Azure using details captured earlier in this section. Update the versions&#46;tf file to match the format shown below. You will need to substitute the `subscription_id`, `client_id`, `client_secret` and `tenant_id` with their respective values.

```
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.59.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
  required_version = ">= 0.13"
}

provider "azurerm" {
  features {}

  subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  client_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  client_secret   = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

## Deploy Code

To deploy the solution, open command prompt for Windows or Terminal for Linux or Mac then navigate to where the directory where the git repository was cloned. See example below.

```
cd C:\azure-terraform-generate-thumbnail-blob-upload-trigger
```

Then run the init command to initialise the working directory.
```
terraform init
```

It is suggested to leave the default variable values in the ariables&#46;tf file. Only update these if absolutely necessary.

The solution can then be deployed to Azure using the apply command.
```
terraform apply -auto-approve
```

# Testing Functionality

To test the deployed solution, login to Azure Portal and upload an image to the 'rawimages' container, hosted in the storage account, that has a '.jpg', '.png' or '.bmp' extension.

You should see that after the Azure Function App triggers, the processed image should be loacted in 'processedimages' whilst leaving the original image untouched. Note that sometime the Auzre fuction can take some time to trigger so you may have to be patient.

# Teardown

To remove any resources created during this deployment, navigate to the directory where the repository was cloned to and run the following command to remove them.

```
terraform destroy -auto-approve
```