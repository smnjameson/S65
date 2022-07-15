import sublime
import sublime_plugin
from string import Template 
import re

from sublime import CompletionItem  

class CustomCompletionListener(sublime_plugin.EventListener):
    def on_query_completions(self, view, prefix, locations):
        return ([], sublime.INHIBIT_WORD_COMPLETIONS )    




class AddKickDocCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        # Walk through each region in the selection
        for region in self.view.sel():
            # Only interested in empty regions, otherwise they may span multiple
            # lines, which doesn't make sense for this command.
            if region.empty():
                # Expand the region to the full line it resides on, excluding the newline
                line = self.view.line(region)

                # Extract the string for the line, and add a newline
                lineContents = self.view.substr(line)

                #Is this line a valid doc signature?
                signature = lineContents.strip()


                if signature[:6] == '.macro':
                    splitsig = signature[7:].split('(')
                    name = splitsig[0].split('_')[1]
                    namespace= splitsig[0].split('_')[0]
                    params=splitsig[1].split(',')
                    self.view.insert(edit, line.begin(), self.getmacro(name, namespace, params))
                    return


                if signature[:14] == '.pseudocommand':
                    splitsig = signature[15:-1].split(' ')
                    name = splitsig[0].split('_')[1]
                    namespace= splitsig[0].split('_')[0]
                    params = (' ').join(splitsig[1:]).split(':')
                    print(params)
                    self.view.insert(edit, line.begin(), self.getcommand(name, namespace, params))
                    return


                if signature[:4] == '.var':
                    splitsig = re.split('[\s|=]', signature[5:].strip())
                    name = '_'.join(splitsig[0].split('_')[1:])
                    namespace= splitsig[0].split('_')[0]
                    self.view.insert(edit, line.begin(), self.getvar(name, namespace))
                    return

                if signature[:9] == '.function':
                    splitsig = signature[10:].split('(')
                    name = splitsig[0].split('_')[1]
                    namespace= splitsig[0].split('_')[0]
                    params=splitsig[1].split(',')
                    self.view.insert(edit, line.begin(), self.getfunction(name, namespace, params))
                    return

            else:
                #DEEBUG prints
       
                sel = self.view.sel()
                region1 = sel[0]
                selectionText = self.view.substr(region1)
                print(selectionText)
                line = self.view.line(region)
                self.view.insert(edit, line.begin(), 
                    '''.print ("%s: $" + toHexString(%s))\n''' % (selectionText, selectionText)
                )


    @classmethod
    def getmacro(self, name, namespace, params):
        # Add the name and namespace
        macro = '''/**
* .macro %s
*
* <add a description here >
* 
* @namespace %s
*
''' % (name, namespace)

        #now add params 
        for param in params:
            param = param.strip().split(')')[0]
            macro += '''* @param {byte} %s <add a description here>
'''  % (param)          


        #now add registers and flags
        macro += '''*
* @registers
* @flags
* 
* @setreg {byte} A <add description here>
*/\n'''
        return macro





    @classmethod
    def getfunction(self, name, namespace, params):
        # Add the name and namespace
        func = '''/**
* .function %s
*
* <add a description here >
* 
* @namespace %s
*
''' % (name, namespace)

        #now add params 
        for param in params:
            param = param.strip().split(')')[0]
            func += '''* @param {byte} %s <add a description here>
'''  % (param)          


        #now add registers and flags
        func += '''*
* @return {byte} <add description here>
*/\n'''
        return func

    @classmethod
    def getcommand(self, name, namespace, params):
        # Add the name and namespace
        command = '''/**
* .pseudocommand %s
*
* <add a description here >
* 
* @namespace %s
*
''' % (name, namespace)

        #now add params 
        for param in params:
            param = param.strip().split(')')[0]
            command += '''* @param {byte} {IMM} %s <add a description here>
'''  % (param)          


        #now add registers and flags
        command += '''*
* @registers
* @flags
* 
* @return {byte} A <add description here> 
*/\n'''
        return command


    @classmethod
    def getvar(self, name, namespace):
        # Add the name and namespace
        var = '''/**
* .var %s
*
* <add a description here >
* 
* @namespace %s
*
*/\n''' % (name, namespace)

        return var