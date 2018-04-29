{
    timmy - Pascal unit for creating chat bots
    Version 1.0.0

    Copyright (C) 2018 42tm Team <fourtytwotm@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
}
Unit timmy;

Interface
Type
    TStrArray = Array of String;

    {
    Metadata refers to two arrays holding data:
    QKeywordsList which holds keywords, and
    ReplyList which holds replies

      QKeywordsList [                                 ReplyList [
                     [*keywords for message 1*],                [*possible answers for message 1*],
                     [*keywords for message 2*],                [*possible answers for message 2*],
                                 ...                                             ...
                                                 ]                                                   ]

    Variables:

      Initialized        : State of initialization
      Enabled            : Acts like Initialized but used in fewer number of functions
      NOfEntries         : Number of entries (elements) in QKeywordsList or ReplyList
      DupesCheck         : Check for duplicate or not (might be time-saving if we don't check for duplicate)
      TPercent           : Minimum percentage of the number of keywords over all the words of the message
                           so that the bot object can "understand" and have a reply.
                           (Sorry I don't have a good way to explain it)
      NoUdstdRep : String to assign to TTimmy.Answer in case there's no possible answer to the given message
    }
    TTimmy = Object
                 Initialized: Boolean;
                 Enabled: Boolean;
                 NOfEntries: Integer;
                 QKeywordsList: Array of Array of String;
                 ReplyList: Array of Array of String;
                 DupesCheck: Boolean;
                 TPercent: Integer;
                 NoUdstdRep: String;
                 Function Init: Integer;
                 Function Add(QKeywords, Replies: TStrArray): Integer; overload;
                 Function Add(KeywordsStr, RepStr: String): Integer; overload;
                 Function Add(KeywordsStr, RepStr: String; KStrDeli, QStrDeli: Char): Integer; overload;
                 Function Remove(QKeywords: TStrArray): Integer; overload;
                 Function Remove(AIndex: Integer): Integer; overload;
                 Procedure Update;
                 Function Answer(TQuestion: String): String;
             End;

Function StrProcessor(S: String): String;
Function StrSplit(S: String; delimiter: Char): TStrArray;
Function CompareStrArrays(ArrayA, ArrayB: TStrArray): Boolean;

Implementation

{
    Given a string, process it so that the first and the last
    character are not space, and there is no multiple spaces
    character in a row.
}
Function StrProcessor(S: String): String;
Var iter: Integer;
    FlagStr: String;
    SpaceOn: Boolean;
Begin
    While S[1] = ' ' do Delete(S, 1, 1);
    While S[Length(S)] = ' ' do Delete(S, Length(S), 1);
    FlagStr := '';
    For iter := 1 to Length(S)
    do If S[iter] <> ' '
       then Begin FlagStr := FlagStr + S[iter]; SpaceOn := False; End
       else Case SpaceOn of
     	      True: Continue;
              False: Begin FlagStr := FlagStr + ' '; SpaceOn := True; End;
     	    End;

    StrProcessor := FlagStr;
End;

{
    Given a string, split the string using the delimiter
    and return an array containing the seperated strings.
}
Function StrSplit(S: String; delimiter: Char): TStrArray;
Var iter, counter: Integer;
    FlagStr: String;
Begin
    S := S + delimiter;
    FlagStr := '';
    counter := -1;

    For iter := 1 to Length(S)
    do If S[iter] <> delimiter
       then FlagStr := FlagStr + S[iter]
       else Begin
              If FlagStr = '' then Continue;
              Inc(counter);
              SetLength(StrSplit, counter + 1);
              StrSplit[counter] := FlagStr;
              FlagStr := '';
            End;

    If counter = -1 then Begin
                           SetLength(StrSplit, 1);
                           StrSplit[0] := S;
                         End;
End;

{
    Given two arrays of strings, compare them.
    Return true if they are the same, false otherwise.
}
Function CompareStrArrays(ArrayA, ArrayB: TStrArray): Boolean;
Var iter: Integer;
Begin
    If Length(ArrayA) <> Length(ArrayB) then Exit(False);
    For iter := 0 to Length(ArrayA) - 1 do If ArrayA[iter] <> ArrayB[iter] then Exit(False);
    Exit(True);
End;

{
    Initialize object with some default values set.
    Return 101 if object is initialized, 100 otherwise.
}
Function TTimmy.Init: Integer;
Begin
    If Initialized then Exit(101);

    DupesCheck := True;
    NoUdstdRep := 'Sorry, I didn''t get that';
    TPercent := 70;
    NOfEntries := 0;
    Update;
    Enabled := True;
    Initialized := True;
    Exit(100);
End;

{
    Add data to bot object's metadata base.
    Data include message's keywords and possible replies to the message.

    Return: 102 if object is not initialized or enabled
            202 if DupesCheck = True and found a match to QKeywords in QKeywordsList
            200 if the adding operation succeed
}
Function TTimmy.Add(QKeywords, Replies: TStrArray): Integer;
Var iter: Integer;
Begin
    If (not Initialized) or (not Enabled) then Exit(102);
    For iter := Low(QKeywords) to High(QKeywords) do QKeywords[iter] := LowerCase(QKeywords[iter]);
    If (DupesCheck) and (NOfEntries > 0)
    then For iter := Low(QKeywordsList) to High(QKeywordsList) do
           If CompareStrArrays(QKeywordsList[iter], QKeywords) then Exit(202);

    Inc(NOfEntries); Update;
    QKeywordsList[High(QKeywordsList)] := QKeywords;
    ReplyList[High(ReplyList)] := Replies;
    Exit(200);
End;

{
    Add data to bot but this one gets string inputs instead of TStrArray inputs.
    This use StrSplit() to split the string inputs (with a space character as the delimiter
    for the message keywords string input and a semicolon character for the replies string input).
    The main work is done by the primary implementation of TTimmy.Add().

    Return: TTimmy.Add(QKeywords, Replies: TStrArray)
}
Function TTimmy.Add(KeywordsStr, RepStr: String): Integer;
Begin
    Exit(Add(StrSplit(KeywordsStr, ' '), StrSplit(RepStr, ';')));
End;

{
    Just like the above implementation of TTimmy.Add() but this one is with custom delimiters.

    Return: TTimmy.Add(QKeywords, Replies: TStrArray)
}
Function TTimmy.Add(KeywordsStr, RepStr: String; KStrDeli, QStrDeli: Char): Integer;
Begin
    Exit(Add(StrSplit(KeywordsStr, KStrDeli), StrSplit(RepStr, QStrDeli)));
End;

{
    Given a set of keywords, find matches to that set in QKeywordsList,
    remove the matches, and remove the correspondants in ReplyList as well.
    This function simply saves offsets of the matching arrays in QKeywordsList
    and then call TTimmy.RemoveByIndex().

    Return: 102 if object is not initialized or not enabled
            308 if the operation succeed
}
Function TTimmy.Remove(QKeywords: TStrArray): Integer;
Var iter, counter: Integer;
    Indexes: Array of Integer;
Begin
    If (not Initialized) or (not Enabled) then Exit(102);

    For iter := Low(QKeywords) to High(QKeywords) do QKeywords[iter] := LowerCase(QKeywords[iter]);
    counter := -1;  // Matches counter in 0-based
    SetLength(Indexes, Length(QKeywordsList));

    // Get offsets of keywords set that match the given QKeywords parameter
    // and later deal with them using TTimmy.RemoveByIndex
      For iter := Low(QKeywordsList) to High(QKeywordsList) do
        If CompareStrArrays(QKeywordsList[iter], QKeywords)
        then Begin
      	       Inc(counter);
               Indexes[counter] := iter;
             End;

    Inc(counter);
    SetLength(Indexes, counter);
    While counter > 0 do
    Begin
      Remove(Indexes[Length(Indexes) - counter] - Length(Indexes) + counter);
      Dec(counter);
    End;
    Exit(308);
End;

Function TTimmy.Remove(AIndex: Integer): Integer;
Var iter: Integer;
Begin
    If (not Initialized) or (not Enabled) then Exit(102);
    If (AIndex < 0) or (AIndex >= NOfEntries) then Exit(305);

    For iter := AIndex to High(QKeywordsList) - 1
    do QKeywordsList[iter] := QKeywordsList[iter + 1];
    For iter := AIndex to High(ReplyList) - 1
    do ReplyList[iter] := ReplyList[iter + 1];

    Dec(NOfEntries); Update;
    Exit(300);
End;

{
    Update metadata to match up with number of entries
}
Procedure TTimmy.Update;
Begin
    If not Initialized then Exit;

    SetLength(QKeywordsList, NOfEntries);
    SetLength(ReplyList, NOfEntries);
End;

{
    Answer the given message, using assets in the metadata
}
Function TTimmy.Answer(TQuestion: String): String;
Var MetaIter, QKIter, QWIter, counter, GetAnswer: Integer;
    FlagQ: String;
    LastChar: Char;
    FlagWords: TStrArray;
Begin
    If (not Initialized) or (not Enabled) then Exit;

    // Pre-process the message
      FlagQ := LowerCase(StrProcessor(TQuestion));
      // Delete punctuation at the end of the message (like "?" or "!")
        While True do Begin
                        LastChar := FlagQ[Length(FlagQ)];
                        Case LastChar of
                          'a'..'z', 'A'..'Z', '0'..'9': Break;
                        Else Delete(FlagQ, Length(FlagQ), 1);
                        End;
                      End;

    FlagWords := StrSplit(FlagQ, ' ');
    For MetaIter := 0 to NOfEntries - 1
    do Begin
         counter := 0;
         For QKIter := Low(QKeywordsList[MetaIter]) to High(QKeywordsList[MetaIter])
         do For QWIter := Low(FlagWords) to High(FlagWords)
            do If FlagWords[QWiter] = QKeywordsList[MetaIter][QKIter] then Inc(counter);

         If counter / Length(QKeywordsList[MetaIter]) * 100 >= TPercent  // Start getting answer
         then Begin
     	        Randomize;
                GetAnswer := Random(Length(ReplyList[MetaIter]));
                Exit(ReplyList[MetaIter][GetAnswer]);
     	      End;
       End;

    Exit(NoUdstdRep);
End;

End.
