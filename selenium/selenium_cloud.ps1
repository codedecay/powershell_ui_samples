#Copyright (c) 2014 Serguei Kouzmine
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.

<#
 CLOUD : '104.131.159.44'
 HOST ONLY : '192.168.56.101'
 BRIDGED : '192.168.0.13'
#>

param (
[string] $filename = 'screenshot',
[string] $hub_host = '',
[string] $hub_port = '4444'

)

if ($hub_host -eq '') {
  $hub_host = $env:HUB_HOST
}

if ($hub_host -eq '') {
  $hub_host = $env:HUB_HOST
}

if ((($hub_host -eq $null) -or ($hub_host -eq ''))) {
  $(throw "Please specify a HUB to run.")
  exit 1
}


function cleanup
{
  param([object]$selenium_ref)
  try {
    $selenium_ref.Value.Quit()
  } catch [exception]{
    # Ignore errors if unable to close the browser
  }

}

# http://stackoverflow.com/questions/8343767/how-to-get-the-current-directory-of-the-cmdlet-being-executed
function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value;
  if ($Invocation.PSScriptRoot)
  {
    $Invocation.PSScriptRoot;
  }
  elseif ($Invocation.MyCommand.Path)
  {
    Split-Path $Invocation.MyCommand.Path
  }
  else
  {
    $Invocation.InvocationName.Substring(0,$Invocation.InvocationName.LastIndexOf("\"));
  }
}

# http://poshcode.org/1942
function assert {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,ParameterSetName = 'Script',Mandatory = $true)]
    [scriptblock]$Script,
    [Parameter(Position = 0,ParameterSetName = 'Condition',Mandatory = $true)]
    [bool]$Condition,
    [Parameter(Position = 1,Mandatory = $true)]
    [string]$message)

  $message = "ASSERT FAILED: $message"
  if ($PSCmdlet.ParameterSetName -eq 'Script') {
    try {
      $ErrorActionPreference = 'STOP'
      $success = & $Script
    } catch {
      $success = $false
      $message = "$message`nEXCEPTION THROWN: $($_.Exception.GetType().FullName)"
    }
  }
  if ($PSCmdlet.ParameterSetName -eq 'Condition') {
    try {
      $ErrorActionPreference = 'STOP'
      $success = $Condition
    } catch {
      $success = $false
      $message = "$message`nEXCEPTION THROWN: $($_.Exception.GetType().FullName)"
    }
  }

  if (!$success) {
    throw $message
  }
}

function cleanup
{
  param([object]$selenium_ref)
  try {
    $selenium_ref.Value.Quit()
  } catch [exception]{
    # Ignore errors if unable to close the browser
  }

}


$shared_assemblies = @(
  'WebDriver.dll',
  'WebDriver.Support.dll',
  'Selenium.WebDriverBackedSelenium.dll',
  'nunit.core.dll',
  'nunit.framework.dll'
)

$env:SCREENSHOT_PATH = 'C:\developer\sergueik\powershell_ui_samples'

$screenshot_path = $env:SCREENSHOT_PATH

$shared_assemblies_path = 'c:\developer\sergueik\csharp\SharedAssemblies'

if (($env:SHARED_ASSEMBLIES_PATH -ne $null) -and ($env:SHARED_ASSEMBLIES_PATH -ne '')) {
  $shared_assemblies_path = $env:SHARED_ASSEMBLIES_PATH
}

pushd $shared_assemblies_path
$shared_assemblies | ForEach-Object {

  if ($host.Version.Major -gt 2) {
    Unblock-File -Path $_;
  }
  Write-Debug $_
  Add-Type -Path $_
}
popd

$phantomjs_executable_folder = 'C:\tools\phantomjs'

  try {
    $connection = (New-Object Net.Sockets.TcpClient)
    $connection.Connect($hub_host,[int]$hub_port)

    $connection = (New-Object Net.Sockets.TcpClient)
    $connection.Close()
  }
  catch {

  write-output $_.Exception.Message
  return -2 
  }

  $capability = [OpenQA.Selenium.Remote.DesiredCapabilities]::Firefox()
  $uri = [System.Uri](('http://{0}:{1}/wd/hub' -f $hub_host,$hub_port))

  $driver = New-Object OpenQA.Selenium.Remote.RemoteWebDriver ($uri,$capability)

# http://selenium.googlecode.com/git/docs/api/dotnet/index.html
[void]$driver.Manage().Timeouts().ImplicitlyWait([System.TimeSpan]::FromSeconds(10))
[string]$base_url = $driver.Url = 'http://www.wikipedia.org';
$driver.Navigate().GoToUrl(('{0}/' -f $base_url))


[OpenQA.Selenium.Remote.RemoteWebElement]$queryBox = $driver.FindElement([OpenQA.Selenium.By]::Id('searchInput'))
$queryBox.Clear()
$queryBox.SendKeys('Selenium')
$queryBox.SendKeys([OpenQA.Selenium.Keys]::ArrowDown)
$queryBox.Submit()
$driver.FindElement([OpenQA.Selenium.By]::LinkText('Selenium (software)')).Click()
$title = $driver.Title

assert -Script { ($title.IndexOf('Selenium (software)') -gt -1) } -Message $title
assert -Script { ($driver.SessionId -eq $null) } -Message 'non null session id'

# Take screenshot identifying the browser
$driver.Navigate().GoToUrl("https://www.whatismybrowser.com/")
[OpenQA.Selenium.Screenshot]$screenshot = $driver.GetScreenshot()

$screenshot.SaveAsFile(('{0}\{1}.{2}' -f $screenshot_path, $filename,  'png' ), [System.Drawing.Imaging.ImageFormat]::Png)

# Cleanup

cleanup ([ref]$selenium)