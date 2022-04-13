import * as vscode from "vscode";
import * as path from "path";
import { masonRemove } from "../mason";

export const removeLocalBrick = async () => {
  try {
    const folder = vscode.workspace.workspaceFolders![0].uri;
    const masonYamlPath = path.join(folder.fsPath, "mason.yaml");
    console.log(masonYamlPath);
    await vscode.workspace.fs.stat(vscode.Uri.file(masonYamlPath));
  } catch (_) {
    vscode.window.showErrorMessage(
      "No mason.yaml was found in the current workspace."
    );
    return;
  }

  const brick = await promptForBrickName();
  if (!brick) return;

  await masonRemove({ brick });
};

export const removeGlobalBrick = async () => {
  const brick = await promptForBrickName();
  if (!brick) return;

  await masonRemove({ brick, global: true });
};

const promptForBrickName = () => {
  return vscode.window.showInputBox({
    placeHolder: "hello",
    prompt: "Enter the brick name.",
  });
};
