package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

type (
	OCCManifest struct {
		Components []Component
	}
	Component struct {
		ComponentKey
		Arguments []string       `json:"Arguments"`
		Command   string         `json:"Command"`
		Comment   string         `json:"Comment"`
		Path      string         `json:"Path"`
		URL       string         `json:"Url"`
		Name      string         `json:"Name"`
		ProductID string         `json:"ProductId"`
		SHA512    string         `json:"sha512"`
		Source    string         `json:"Source"`
		Target    string         `json:"Target"`
		Value     string         `json:"Value"`
		Values    []string       `json:"Values"`
		DependsOn []ComponentKey `json:"DependsOn"`
	}
	ComponentKey struct {
		ComponentName string `json:"ComponentName"`
		ComponentType string `json:"ComponentType"`
	}
)

func main() {
	resp, err := http.Get("https://raw.githubusercontent.com/mozilla-releng/OpenCloudConfig/master/userdata/Manifest/gecko-1-b-win2012.json")
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()
	dec := json.NewDecoder(resp.Body)
	var o OCCManifest
	err = dec.Decode(&o)
	if err != nil {
		panic(err)
	}

	orderedComponents := OrderComponents(o.Components)
	logCount := 0
	for _, c := range orderedComponents {
		fmt.Println("")
		fmt.Println("# " + c.ComponentName + ": " + c.Comment)
		switch c.ComponentType {
		case "ChecksumFileDownload":
			fmt.Printf(`$client.DownloadFile("%s", "%s")`+"\n", c.Source, c.Target)
		case "CommandRun":
			fmt.Printf(`Start-Process "%s" -ArgumentList "%s" -Wait -NoNewWindow -PassThru -RedirectStandardOutput "C:\logs\%v.log" -RedirectStandardError "C:\logs\%v.log"`+"\n", c.Command, strings.Join(c.Arguments, " "), logCount, logCount)
			logCount++
		case "DirectoryCreate":
			fmt.Printf(`md "%s"`+"\n", c.Path)
		case "DisableIndexing":
			fmt.Print(`Get-WmiObject Win32_Volume -Filter "IndexingEnabled=$true" | Set-WmiInstance -Arguments @{IndexingEnabled=$false}` + "\n")
		case "EnvironmentVariableSet":
			fmt.Printf(`[Environment]::SetEnvironmentVariable("%s", "%s", "%s")`+"\n", c.Name, c.Value, c.Target)
		case "EnvironmentVariableUniquePrepend":
			fmt.Printf(`[Environment]::SetEnvironmentVariable("%s", "%s;%%%s%%", "%s")`+"\n", c.Name, strings.Join(c.Values, ";"), c.Name, c.Target)
		case "ExeInstall":
			fmt.Printf(`$client.DownloadFile("%s", "%s")`+"\n", c.URL, "C:\\temp.exe")
			fmt.Printf(`Start-Process "%s" -ArgumentList "%s" -Wait -NoNewWindow -PassThru -RedirectStandardOutput "C:\logs\%v.log" -RedirectStandardError "C:\logs\%v.log"`+"\n", "C:\\temp.exe", strings.Join(c.Arguments, " "), logCount, logCount)
			logCount++
		case "FileDownload":
			fmt.Printf(`$client.DownloadFile("%s", "%s")`+"\n", c.Source, c.Target)
		case "FirewallRule":
		case "MsiInstall":
		case "RegistryKeySet":
		case "RegistryValueSet":
		case "ServiceControl":
		case "SymbolicLink":
		case "WindowsFeatureInstall":
		case "ZipInstall":
		}
	}
}

// OrderComponents will return a sorted copy of comps such that dependencies of
// a component appear earlier in the list than the component itself. Cyclic
// dependencies are not checked for.
func OrderComponents(comps []Component) (ordered []Component) {
	ordered = make([]Component, len(comps), len(comps))
	i := 0
	addedKeys := map[ComponentKey]bool{}
	compByKey := map[ComponentKey]Component{}
	for _, c := range comps {
		key := ComponentKey{ComponentName: c.ComponentName, ComponentType: c.ComponentType}
		compByKey[key] = c
	}
	var add func(c Component)
	add = func(c Component) {
		key := ComponentKey{ComponentName: c.ComponentName, ComponentType: c.ComponentType}
		if !addedKeys[key] {
			for _, d := range c.DependsOn {
				add(compByKey[d])
			}
			ordered[i] = c
			addedKeys[key] = true
			i++
		}
	}
	for _, c := range comps {
		add(c)
	}
	return
}
