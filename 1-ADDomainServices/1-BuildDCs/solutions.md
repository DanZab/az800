[Back to lesson page](README.md)

# Solutions
## Lab Solutions

<details><summary>Scenario Title 1</summary>
Solution Steps</details>

## Quiz

<details><summary>1. What are flexible single master operation (FSMO) roles?</summary>
<br><br>
> FSMO roles identify which domain controller is responsible for certain domain functions that have to be managed or performed by a single domain controller. It is best practice to assign all FSMO roles to the same "primary" DC.
</details>

<details><summary>2. What is a domain name?</summary>
<br><br>
> A domain name, just like an internet domain name, is the DNS name used to identify your local Active Directory domain.
</details>

<details><summary>2. Why would you use Read Only Domain Controller (RODC)?</summary>
<br><br>
> RODCs should only be used in cases where a Domain Controller cannot be physically secured. It prevents someone from obtaining a complete copy of the Active Directory database through the physical hard drives.
</details>

<details><summary>3. You are adding a new DC to an existing domain. The new DC is on the same network as the existing DCs but you are encountering an error when attempting to promote it. What could be two potential causes?</summary>
<br><br>
> - There may be a firewall blocking communication to the existing DC
> - Your new DC may not be configured to use the AD Domain for DNS

</details>

<details><summary>4. What function does DNS serve in an AD domain?</summary>
<br><br>
> DNS resolution is required for ALL active directory operations. You cannot contact or interact with a domain controller without using DNS. Any login or authentication activity in active directory uses the AD domain name to look up a domain controller, without DNS working, the client would be unable to connect.
</details>

<details><summary>5. What is a Domain Admin account and what makes them unique?</summary>
<br><br>
> Domain admins are the most highly privileged accounts in an AD environment. A domain admin account can be used to gain access to any system connected to an AD domain. It is best practice to limit the use of these accounts to only domain administration tasks on the DCs themselves.
</details>
