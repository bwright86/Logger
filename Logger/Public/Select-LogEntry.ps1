


function Select-LogEntry {
    [CmdletBinding(DefaultParameterSetName="StrictPatternMatching")]
    Param (
        # Individual log entries. Can be objects or strings.
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipeline=$true)]
        $InputObject,
        # Property to use for pattern recognition.
        [Parameter(Mandatory=$true,
                   Position=1,
                   ParameterSetName="StrictPatternMatching")]
        [Parameter(Mandatory=$true,
                   Position=1,
                   ParameterSetName="LoosePatternMatching")]
        [string]
        $Property,
        # The pattern to match, with each element being a single object property. The order and value must match exactly against the property
        [Parameter(Mandatory=$true,
                   Position=2,
                   ParameterSetName="StrictPatternMatching")]
        [Parameter(Mandatory=$true,
                   Position=2,
                   ParameterSetName="LoosePatternMatching")]
        [string[]]
        $Pattern,
        # Loose matching allows non-consecutive patterns to be found in the input.
        [Parameter(Mandatory=$true,
                   Position=3,
                   ParameterSetName="LoosePatternMatching")]
        [switch]
        $Loose,
        # A Where-Object type scriptblock.
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName="FilterAndContext")]
        [scriptblock]
        $Where,
        # The number of entries to include before the match.
        [Parameter(Mandatory=$false,
                   Position=1,
                   ParameterSetName="FilterAndContext")]
        $Previous = 0,
        # The number of entries to include after the match.
        [Parameter(Mandatory=$false,
                   Position=2,
                   ParameterSetName="FilterAndContext")]
        $Next = 0
    )

    Begin {

        $patternProps = @{
            "PatternIndex" = -1;
            "LogEntries" = @();
            "FullPatternMatch" = $false;
        }

        switch ($PSCmdlet.ParameterSetName) {
            "StrictPatternMatching" {

                "`"Strict Pattern Matching`" has been selected." | Write-Verbose
                "Pattern Count: $($Pattern.Count)" | Write-Verbose

                $patternStartFound = $false
                $patternMatchIndex = 0

                $patternResult = @()
            
            } # Case: PatternMatching
            "LoosePatternMatching" {

                "`"Loose Pattern Matching`" has been selected." | Write-Verbose

                $patternResult = @()
                
            } # Case: LoosePatternMatching
            "FilterAndContext" {

                "Filter and Context has been selected." | Write-Verbose
                "On match, returning $Previous previous entries and the next $Next entries."
                
                $allInput = @()

            } # Case: FilterAndContext
        } # Switch: ParametersSetName

        
    }

    Process {
        
        switch ($PSCmdlet.ParameterSetName) {
            "StrictPatternMatching" {
                
                if (!($patternStartFound) -and $InputObject.$Property -eq $Pattern[0]) {
                    
                    "+ First element in pattern found." | Write-Verbose

                    $patternResult += $InputObject
                    
                    $patternStartFound = $true
                    
                    $patternMatchIndex++

                } elseif ($patternStartFound -and $InputObject.$Property -eq $Pattern[$patternMatchIndex]) {
                    
                    "+ Pattern $($patternMatchIndex + 1) has been found." | Write-Verbose

                    $patternResult += $InputObject

                    # Entire pattern was found, current pattern result will be ouput.
                    if ( ($patternMatchIndex + 1) -eq $Pattern.Count) {

                        "+ Final pattern found, outputting the results" | Write-Verbose

                        $patternResult | Write-Output

                        $patternStartFound = $false
                        
                        $patternMatchIndex = 0
    
                        $patternResult = @()
                    }

                    $patternMatchIndex++

                } elseif ($patternStartFound) {

                    "- Next pattern not found, resetting..." | Write-Verbose

                    $patternStartFound = $false

                    $patternMatchIndex = 0

                    $patternResult = @()
                }

            } # Case: PatternMatching
            "LoosePatternMatching" {

                if ($InputObject.$Property -eq $Pattern[0]) {

                    $newPatternMatch = New-Object pscustomobject -Property $patternProps

                    $newPatternMatch.PatternIndex = 0
                    $newPatternMatch.LogEntries += $InputObject

                    $patternResult += $newPatternMatch
                } elseif ($InputObject.$Property -in $Pattern) {
                    
                    foreach ($result in $patternResult | Where-Object {$_.FullPatternMatch -ne $true}) {

                    }
                }
                
                
            } # Case: LoosePatternMatching
            "FilterAndContext" {
                $allInput += $InputObject
            } # Case: FilterAndContext
        } # Switch: ParametersSetName
        
    }

    End {

        switch ($PSCmdlet.ParameterSetName) {
            "StrictPatternMatching" {

            } # Case: PatternMatching
            "LoosePatternMatching" {
                
                
            } # Case: LoosePatternMatching
            "FilterAndContext" {
                
                [array]$matches = $allInput | Where-Object $Where

                "Found $($matches.count) match(es) to return."

                foreach ($match in $matches) {
                    $index = $allInput.indexOf($match)

                    $startIndex = $index - $Previous
                    $endIndex = $index + $Next

                    $allInput[$startIndex..$endIndex] | Write-Output
                }

            } # Case: FilterAndContext
        } # Switch: ParametersSetName

    }
}