$page_source = @"
               <!--Pre load map to allow lightbox to be properly sized-->
               <img style="display: none;" src="/~/media/Images/Itineraries/Maps/JAX-BAE-04gif.ashx" />

				<h2>Your Trip
					
					<a class="itinLightBox" href="/Pages/ItineraryLightbox.aspx?itinCode=BAE&amp;durDays=4&amp;portCode=JAX&amp;sailDate=03052015">
					<span class="viewitin"> </span>

"@
$page_source =  ($page_source -join '')
<#
if (($page_source -join '') -match '/~/media/Images/Itineraries/Maps') {
  $results = ($page_source -join '') | where { $_ -match '(?<media>/~/media/Images/Itineraries/Maps[^\"]+)' } |
  ForEach-Object { New-Object PSObject –prop @{ Media = $matches['media']; } }
  
  Write-Output ('Found media images: {0}' -f $results.Media )

}
#>
if ($page_source -match '/~/media/Images/Itineraries/Maps') {
  $results = $page_source | where { $_ -match '(?<media>/~/media/Images/Itineraries/Maps[^\"]+)' } |
  ForEach-Object { New-Object PSObject –prop @{ Media = $matches['media']; } }
  
  Write-Output ('Found media images: {0}' -f $results.Media )

}