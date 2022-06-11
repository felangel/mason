import { lstatSync } from "fs";
import * as vscode from "vscode";
import {
  Uri,
  window
} from "vscode";
import { masonList, masonInfo, masonMake } from "../mason";

export const makeBrick = async (uri: Uri) => {
  if (!lstatSync(uri.fsPath).isDirectory()) {
    window.showErrorMessage("Please select a valid directory");
    return;
  }

  const cwd = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
  if (!cwd) {
    return;
  }

  const targetDirectory = uri.fsPath;
  if (!targetDirectory) {
      return;
  }

  const bricks = await getListOfBricks({ cwd });
  if (!bricks) {
    window.showErrorMessage("No bricks found in the workspace");
    return;
  }

  const brickName = await promptForBrickName({ bricks });
  if (!brickName) {
      return;
  }

  const rawBrick = await masonInfo({ cwd, brickName });
  const brick = JSON.parse(rawBrick);
  
  const name : string = brick.name;

  let vars : string[] = [];
  for (let key in brick.vars) {
    const value = await promptForValue(brick.vars[key]);
    if (!value) {
      return;
    }
    vars.push(`--${key}=${value.toString()}`);
  }
  const args = vars.join(" ");

  await masonMake({ cwd, targetDirectory, name, args });
};

const promptForBrickName = ({
    bricks,
}: {
    bricks: string[];
}) => {
    return vscode.window.showQuickPick(bricks, {
        canPickMany: false,
        matchOnDescription: true,
        placeHolder: `Pick a brick`,
      });
};

const getListOfBricks = async ({
    cwd,
  }: {
    cwd: string;
  }): Promise<string[] | undefined> => {
    const rawOutput = await masonList({ cwd });
    var rawLines = rawOutput.split("\n");
    rawLines.shift();
    rawLines.pop();
    const bricks = rawLines.map((line) => line.split(" ")[1]);
    if (bricks[0] === "(empty)") {
        return;
    }
    return bricks;
};

const promptForValue = async (args : any): Promise<string | undefined> => {
  if (args.type === "string" || args.type === "number") {
    return promptForPrimitive(args.prompt, args.default);
  }
  if (args.type === "boolean") {
    return promptForBoolean(args.prompt, args.default);
  }
  if (args.type === "enum") {
    return promptForEnum(args.prompt, args.default, args.values);
  }
  if (args.type === "array") {
    return promptForArray(args.prompt, args.defaults, args.values);
  }
  window.showInformationMessage(`${args.type} type is not supported, settings the default value.`);
  if (args.default) {
    return args.default.toString();
  }
  if (args.defaults) {
    return args.defaults.toString();
  }
  window.showErrorMessage(`Could not find a default value for ${args.name}.`);
  return;
};

const promptForPrimitive = async (title: string, _default: string): Promise<string | undefined> => {
  let result = await vscode.window.showInputBox({
    placeHolder: _default,
    prompt: title,
  });
  if (result === "") {
    return _default;
  }
  return result;
};

const promptForBoolean = async (title: string, _default: boolean): Promise<string | undefined> => {
  const items = [
    _default.toString(),
    (!_default).toString(),
  ];
  return vscode.window.showQuickPick(items, {
    canPickMany: false,
    placeHolder: title,
  });
};

const promptForEnum = async (title: string, _default: string, items: string[]): Promise<string | undefined> => {
  return vscode.window.showQuickPick([
    _default,
    ...items.filter((item) => item !== _default),
  ], {
    canPickMany: false,
    placeHolder: title,
  });
};

const promptForArray = async (title: string, _default: string[], items: string[]): Promise<string | undefined> => {
  const options: vscode.QuickPickItem[] = items.map((item) => ({
    label: item,
    picked: _default.includes(item),
  }));
  return vscode.window.showQuickPick(
    options,
   {
    canPickMany: true,
    placeHolder: title,
  }).then((l) => l?.map((i) => i.label).join(","));
};