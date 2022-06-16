import * as _ from "lodash";
import * as vscode from "vscode";
import * as path from "path";
import { masonAdd } from "../mason";

export const addLocalBrick = async () => {
  const cwd = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
  if (_.isNil(cwd)) {
    return;
  }

  try {
    const masonYamlPath = path.join(cwd, "mason.yaml");
    await vscode.workspace.fs.stat(vscode.Uri.file(masonYamlPath));
  } catch (_) {
    vscode.window.showErrorMessage(
      "No mason.yaml was found in the current workspace."
    );
    return;
  }

  const brick = await promptForBrickName();
  if (_.isNil(brick)) {
    return;
  }

  await masonAdd({ cwd, brick });
};

export const addGlobalBrick = async () => {
  const cwd = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
  if (_.isNil(cwd)) {
    return;
  }

  const brick = await promptForBrickName();
  if (_.isNil(brick)) {
    return;
  }

  await masonAdd({ cwd, brick, global: true });
};

const promptForBrickName = () => {
  return vscode.window.showInputBox({
    placeHolder: "hello",
    prompt: "Enter the brick name.",
  });
};
