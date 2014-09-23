<table>
<tr>
    <td>Name</td><td>Phone</td>
</tr
{foreach $users as $user}
{strip}
   <tr bgcolor="{cycle values="#aaaaaa,#cccccc"}">
      <td>{$user.name}</td>
      <td>{$user.phone}</td>
   </tr>
{/strip}
{/foreach}
</table>



