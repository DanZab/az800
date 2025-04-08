[Back to lesson page](README.md)

# Solutions
## Lab Solutions

<details><summary>1 - Install two Domain Controllers</summary>

After connecting to your lab server (DC1):
1. Install the AD DS Role
    1. From Server Manager, Manage > Add Roles and Features > Server Roles
    2. Select Active Directory Domain Services (include management tools)
    3. Click Next until you can click Install, wait for install to complete

2. Promote the first Domain Controller
    1. Select 'Add a new forest', and specify a new root domain name, next
    1. Create a DSRM password, next
    1. Skip the DNS registration screen
    1. (Optional) Customize the NetBIOS name
    1. Leave the Paths default, click next twice
    1. Ignore the warnings and Install

3. The server will restart, reconnect and validate that DNS and AD are both running

4. RDP from DC1 into DC2

5. Test network and DNS connectivity
    1. Ping DC1, do you get a reply?
    2. Ping the domain name you configured in step 2-1

6. DNS will not be working, open the network adapter settings and set the primary DNS server to the IP of DC1 you saw in step 5-1

7. Retest and validate DNS is working (step 5-2)

8. Redo step 1 on DC2

9. Promote DC2 as a domain controller
    1. Add to existing domain, specify your domain name from step 2-1
    1. Add the required credentials, click next
    1. Set a DSRM password, next
    1. Click next until you can click Install

10. After DC2 restarts, open AD Users and Computers and validate that DC2 is listed under Domain Controllers

11. Log into DC2 with domain credentials to confirm

</details>

## Quiz

<details><summary>1. What are flexible single master operation (FSMO) roles?</summary>
<br>

> FSMO roles identify which domain controller is responsible for certain domain functions that have to be managed or performed by a single domain controller. It is best practice to assign all FSMO roles to the same "primary" DC.
</details>

<details><summary>2. What is a domain name?</summary>
<br>

> A domain name, just like an internet domain name, is the DNS name used to identify your local Active Directory domain.
</details>

<details><summary>2. Why would you use Read Only Domain Controller (RODC)?</summary>
<br>

> RODCs should only be used in cases where a Domain Controller cannot be physically secured. It prevents someone from obtaining a complete copy of the Active Directory database through the physical hard drives.
</details>

<details><summary>3. You are adding a new DC to an existing domain. The new DC is on the same network as the existing DCs but you are encountering an error when attempting to promote it. What could be two potential causes?</summary>
<br>

> - There may be a firewall blocking communication to the existing DC
> - Your new DC may not be configured to use the AD Domain for DNS

</details>

<details><summary>4. What funcion does DNS serve in an AD domain?</summary>
<br>

> DNS resolution is required for ALL active directory operations. You cannot contact or interact with a domain controller without using DNS. Any login or authentication activity in active directory uses the AD domain name to look up a domain controller, without DNS working, the client would be unable to connect.
</details>

<details><summary>5. What is a Domain Admin account and what makes them unique?</summary>
<br>

> Domain admins are the most highly privileged accounts in an AD environment. A domain admin account can be used to gain access to any system connected to an AD domain. It is best practice to limit the use of these accounts to only domain administration tasks on the DCs themselves.
</details>
