[Back to lesson page](README.md)

## Lab Deployment
See the [/deployment_guide.md](../../../deployment_guide.md) for instructions on deploying the environments with terraform or the GUI. This guide has instructions for locating your `azure_subscription_id` or public IP address if needed.

Use the terraform directory to deploy with terraform.

Use this button to deploy with the GUI:

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDanZab%2Faz800%2Frefs%2Fheads%2Fmain%2Ftemplates%2F1.1.AD.json)

> [!CAUTION]
> Do not forget to run `terraform destroy` or to delete the resource group with your lab resources when you are finished!
>
> VMs are cheap to run for a couple hours but quickly become expensive if they are left running.

### Lab Information

> - The default username to connect is `lab_admin`
> - You will be prompted for the password to set
> - These credentials will not work after you promote the domain controllers, you will need to use domain admin credentials to connect after promotion.

> - There are three servers in this lab:
>     - APEXDC1 10.0.0.4: A domain controller running the apex.local domain
>     - APEXSRV 10.0.0.5: A member server in the apex.local domain
>     - EUDC1 10.0.0.6: A default windows server
>     - EUSRV 10.0.0.7: A member server that can be joined to the EU domain
>     - SUMMITDC 10.0.0.8: A domain controller running the summit.corp domain

**Lab Diagram:**

![](../../img/AZ800-forest.png)

# Lab Scenarios

> [!IMPORTANT]
> Be mindful of cost for this lab. It is running five servers so it is more expensive than most other labs.
>
> If you want to reduce the cost, you can edit the `servers.tf` file and delete/comment out the APEXSRV (lines 11-17) and EUSRV (lines 24-29) blocks before deploying the lab. This will reduce the number of servers to three.

1. [Configure a Forest and a transitive, one-way trust](#1---install-two-domain-controllers)

---


## Configure a Forest and a transitive, one-way trust
Scenario: 

### Completion Criteria
To complete this lab you should have the following criteria configured:
- The `apex.local` forest should have two domains; `apex.local`, and `eu.apex.local`
- You should be able to log into the `summit.corp` domain with users from both `apex.local` and `eu.apex.local`

### Lesson Objectives Covered:
