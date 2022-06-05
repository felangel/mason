import * as vscode from "vscode";
import {
  addLocalBrick,
  addGlobalBrick,
  init,
  makeBrick,
  removeLocalBrick,
  removeGlobalBrick,
} from "./commands";
import { onFileSaved } from "./events";

export async function activate(context: vscode.ExtensionContext) {
  context.subscriptions.push(
    vscode.workspace.onDidSaveTextDocument(onFileSaved),
    vscode.commands.registerCommand("mason.init", init),
    vscode.commands.registerCommand("mason.add-local-brick", addLocalBrick),
    vscode.commands.registerCommand("mason.add-global-brick", addGlobalBrick),
    vscode.commands.registerCommand("mason.make-brick", makeBrick),
    vscode.commands.registerCommand(
      "mason.remove-local-brick",
      removeLocalBrick
    ),
    vscode.commands.registerCommand(
      "mason.remove-global-brick",
      removeGlobalBrick
    )
  );
}
