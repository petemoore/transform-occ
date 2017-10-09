package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
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

func (c ComponentKey) String() string {
	return fmt.Sprintf("{ComponentName: '%v', ComponentType: '%v'}", c.ComponentName, c.ComponentType)
}

func main() {
	if len(os.Args) != 2 {
		log.Fatal("Please specify a single workerType, e.g. `transform-occ gecko-1-b-win2012`")
	}
	workerType := os.Args[1]
	resp, err := http.Get("https://raw.githubusercontent.com/mozilla-releng/OpenCloudConfig/master/userdata/Manifest/" + workerType + ".json")
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

	orderedComponents, err := OrderComponents(o.Components)
	if err != nil {
		panic(err)
	}
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

type DependencyDoesNotExist struct {
	ComponentKey  ComponentKey
	Dependency    ComponentKey
	ComponentList []Component
}

func (d *DependencyDoesNotExist) Error() string {
	return fmt.Sprintf("Component %v depends on %v which is not defined in component list", d.ComponentKey, d.Dependency)
}

type DuplicateComponentKey struct {
	Key           ComponentKey
	ComponentList []Component
}

func (d *DuplicateComponentKey) Error() string {
	return fmt.Sprintf("Duplicate component key found: %v", d.Key)
}

type CyclicDependency struct {
	Key           ComponentKey
	Chain         []ComponentKey
	ComponentList []Component
}

func (d *CyclicDependency) Error() string {
	keyStrings := make([]string, len(d.Chain), len(d.Chain))
	for i, key := range d.Chain {
		keyStrings[i] = key.String()
	}
	return "Cyclic dependency found in component list: " + strings.Join(keyStrings, " -> ") + " -> " + d.Key.String()
}

// OrderComponents will return a sorted copy of comps such that dependencies of
// a component appear earlier in the list than the component itself. Returns an
// error if there is a cyclic dependency, or if comps contains non-unique
// component keys.
func OrderComponents(comps []Component) (ordered []Component, err error) {
	ordered = make([]Component, len(comps), len(comps))
	i := 0
	addedKeys := map[ComponentKey]bool{}
	compByKey := map[ComponentKey]Component{}
	for _, c := range comps {
		key := ComponentKey{ComponentName: c.ComponentName, ComponentType: c.ComponentType}
		if _, exists := compByKey[key]; exists {
			return nil, &DuplicateComponentKey{
				ComponentList: comps,
				Key:           key,
			}
		}
		compByKey[key] = c
	}
	for key, comp := range compByKey {
		for _, dependency := range comp.DependsOn {
			if _, exists := compByKey[dependency]; !exists {
				return nil, &DependencyDoesNotExist{
					ComponentKey:  key,
					Dependency:    dependency,
					ComponentList: comps,
				}
			}
		}
	}
	var add func(key ComponentKey, dependencyChain []ComponentKey) error
	add = func(key ComponentKey, dependencyChain []ComponentKey) error {
		if !addedKeys[key] {
			// maintaining a map of keys may have been more efficient, but would require more complex code
			// so just loop through all keys in dependency chain for now
			for _, k := range dependencyChain {
				if key == k {
					return &CyclicDependency{
						Key:           key,
						Chain:         dependencyChain,
						ComponentList: comps,
					}
				}
			}
			dependencyChain = append(dependencyChain, key)
			for _, d := range compByKey[key].DependsOn {
				err = add(d, dependencyChain)
				if err != nil {
					return err
				}
			}
			ordered[i] = compByKey[key]
			addedKeys[key] = true
			i++
		}
		return nil
	}
	for _, c := range comps {
		key := ComponentKey{ComponentName: c.ComponentName, ComponentType: c.ComponentType}
		err = add(key, []ComponentKey{})
		if err != nil {
			return nil, err
		}
	}
	return
}
