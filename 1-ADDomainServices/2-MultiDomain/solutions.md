[Back to lesson page](README.md)

# Solutions
## Lab Solutions

<details><summary>Configure a Forest and a transitive, one-way trust

Scenario: You are an administrator at Apex International. Your legal department wants to segregate the European division into it's own authentication and administrative boundary. You still need to maintain the ability for central IT administrators to manage servers if needed. You must configure an eu child domain and validate that there is a group in the child domain that contains the server administrators from the parent. (Your administrator accounts have a '-ADM' suffix and are located in the People/Admins OU.)

Apex International has also acquired the Summit Corporation. Your IT team needs to be able to manage the `summit.corp` domain to facilitate the technical transition using their `apex.local` accounts. The IT team from Summit does not require any access to the Apex domain.

### Completion Criteria
To complete this lab you should have the following criteria configured:
- The `apex.local` forest should have two domains; `apex.local`, and `eu.apex.local`
- There should be a security group in `eu.apex.local` that contains the admin users from `apex.local`
- You should be able to log into the `summit.corp` domain with users from both `apex.local` and `eu.apex.local`
- You should not be able to log into either `apex.local` domains using a `summit.corp` user

### Lesson Objectives Covered:
- Configure and manage forest and domain trusts
</summary>

## Solution

### Create the child domain
- Connect to EUDC1 (10.0.0.6) and configure DNS to point to APEXDC1 (10.0.0.4)
- Install the AD DS role and promote it to a Domain Controller
    - Choose 'Add a new domain to an existing forest'
    - Parent Domain: apex.local
    - Child Domain: eu
- Create a Universal Security group in `eu.apex.local`
- Add members to the group, click the **location** button and select the `apex.local` domain, add the -ADM users from the People/Admins OU

### Create the one-way trust
- From the apexdc1.apex.local server:
    - Open the DNS console and create a Conditional Forwarder for `summit.corp` to 10.0.0.8
- From the summitdc.summit.corp server:
    - Open the DNS console and create a Conditional Forwarder for `apex.local` to 10.0.0.4
- From the apexdc1.apex.local server:
    - Open Active Directory Domains and Trusts
    - Right click the apex.local domain and click the Trusts tab
    - Create a new **incoming** trust, specify the summit.corp domain
    - Choose a transitive trust, you can choose either forest trust or selective authentication

- Test the trust by connecting to `summit.corp`, open AD Users and Computers and modify the Administrators group under the Built-In OU. Add any apex.local user. Once the user has been added, log off and attempt to log back into summitdc.summit.corp using the apex user you configured.
    - If you chose selective authentication when configuring the trust, you also need to adjust the security permissions on the DC and add the apex user with "authenticate user" permissions.
</details>

## Quiz

<details><summary>1. What are the prerequisites for configuring a Domain Controller and how do you test them?</summary>
You must have Network Connectivity (successfully ping IP address), and DNS resolution (successfully ping the DNS name).</details>

<details><summary>2. You are the administrator for the `apex.local` domain. You configure an **incoming** one-way trust with the `summit.corp` domain. Assuming that all permissions are already configured, are you able to log into resources in the `summit.corp` domain or would an admin from `summit.corp` be able to log into resources in the `apex.local` domain?</summary>
If you are on `apex.local` and you configure an Incoming, One-Way trust from `summit.corp`, you would be able to log into `summit.corp` resources with your apex credentials.</details>

<details><summary>3. What security groups are only available in the **parent** domain within an Active Directory forest?</summary>
The Enterprise Admin groups and the Schema Admins group.</details>

<details><summary>4. What is the difference between a transitive and non-transitive trust?</summary>
A transitive trust allows authentication from any domain within the trusted forest. A non-transitive trust would require that explicit trusts are defined for each domain, regardless of whether they are in the same forest.</details>

<details><summary>5. You have 3 forests, named A, B, and C. A and B have a transitive trust configured, and B and C also have a transitive trust configured. Would resources in A be trusted in C?</summary>
No, transitive trusts only extend to forest members. It would not extend the trust to additional trusted forests.</details>

<details><summary>6. What is the difference between an Enterprise Admin and a Domain Admin?</summary>
An Enterprise Admin has administrator rights over all the domains within a forest. Domain Admins are limited to a single domain.</details>

<details><summary>7. If you are creating a group that will contain users from another domain in the forest, what group scope must be set?</summary>
A group scope must be set to Universal to allow adding members from another domain in the forest.</details>