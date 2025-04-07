[Back to lesson page](README.md)

# Lab Scenarios

> [!IMPORTANT]
> You should set aside enough time to do all of these labs in order. Because this lesson involves installing the Domain Controllers, you cannot start with the demo AD lab environment like the other lessons.

1. [Install two Domain Controllers](#1---install-two-domain-controllers)
2. [Transfer FSMO Roles](#2---transfer-fsmo-roles)

## Lab Deployment
You can use the [terraform](terraform/) directory to deploy the resources or if you wish, you can press the button below to deploy the resources through an ARM template in your environment:

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDanZab%2Faz800%2Frefs%2Fheads%2Fmain%2Ftemplates%2F1.1.AD.json)
---

## 1 - Install two Domain Controllers
Scenario: You are the sys admin for a new startup, you need to stand up a new domain with two domain controllers for redundancy.

### Completion Criteria
This lab is complete when you have two domain controllers who are members of the same domain, you should be able to log into either server with the same domain credentials

### Lesson Objectives Covered:
- Deploy and manage domain controllers on-premises
- Deploy and manage domain controllers in Azure

---

## 2 - Transfer FSMO Roles
Scenario: (Using the two DCs you created in the previous scenario) Your primary Domain Controller is out of date and needs to be retired. Document how to identify the primary DC, make a new server the primary, and then retire the original.

### Completion Questions
1. What DC was the primary?
2. What DC is the new primary?
3. How did you identify and transition to a new primary DC?

### Lesson Objectives Covered
- Troubleshoot flexible single master operation (FSMO) roles