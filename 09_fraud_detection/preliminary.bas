Attribute VB_Name = "module1"
Sub preliminary()
Dim ws As Worksheet
Set ws = ThisWorkbook.Sheets("training_set")
' return last column
lastclo = ws.Cells(1, Columns.Count).End(xlToLeft).Column
' return last row
lastrow = ws.Cells(Rows.Count, 1).End(xlUp).Row
' add new column, called "Fraud_outcome"
ws.Cells(1, lastclo + 1) = "Fraud_outcome"
' for loop to populate Fraud_outcome column
For x = 2 To lastrow
If ws.Cells(x, 2) = 1 Then
   ws.Cells(x, lastclo + 1) = "Fraud"
Else
   ws.Cells(x, lastclo + 1) = "Normal"
End If
Next x

' add new column, called "Region"
ws.Cells(1, lastclo + 2) = "Region"
' for loop to populate Region column
For x = 2 To lastrow
Select Case ws.Cells(x, 3)
  Case "Connecticut", "Maine", "Massachusetts", "New Hampshire", "Rhode Island", "Vermont", "New Jersey", "New York", "Pennsylvania"
       ws.Cells(x, lastclo + 2) = "Northeast"
  Case "Illinois", "Indiana", "Michigan", "Ohio", "Wisconsin", "Iowa", "Kansas", "Minnesota", "Missouri", "Nebraska", "North Dakota", "South Dakota"
       ws.Cells(x, lastclo + 2) = "Midwest"
  Case "Delaware", "Florida", "Georgia", "Maryland", "North Carolina", "South Carolina", "Virginia", "District of Columbia", "West Virginia", "Alabama", "Kentucky", "Mississippi", "Tennessee", "Arkansas", "Louisiana", "Oklahoma", "Texas"
       ws.Cells(x, lastclo + 2) = "South"
  Case "Arizona", "Colorado", "Idaho", "Montana", "Nevada", "New Mexico", "Utah", "Wyoming", "Alaska", "California", "Hawaii", "Oregon", "Washington"
       ws.Cells(x, lastclo + 2) = "West"
End Select
Next x
End Sub

