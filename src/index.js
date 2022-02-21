import "./main.css";
import { Elm } from "./Main.elm";
import * as nearAPI from "near-api-js";
import getConfig from "./config";
import "elm-canvas/elm-canvas";

const env = process.env.ELM_APP_NEAR_ENV;

const nearConfig = getConfig(env);
const GAS_FEE = "300000000000000";

// Initializing contract
async function initContract() {
  // Initializing connection to the NEAR TestNet
  const near = await nearAPI.connect({
    keyStore: new nearAPI.keyStores.BrowserLocalStorageKeyStore(),
    ...nearConfig,
  });

  // Needed to access wallet
  const walletConnection = new nearAPI.WalletConnection(near);

  // Load in account data
  let currentUser;
  if (walletConnection.getAccountId()) {
    currentUser = {
      accountId: walletConnection.getAccountId(),
      balance: (await walletConnection.account().state()).amount,
    };
  }

  // Initializing our contract APIs by contract name and configuration
  const contract = await new nearAPI.Contract(
    walletConnection.account(),
    nearConfig.contractName,
    {
      // View methods are read-only – they don't modify the state, but usually return some value
      viewMethods: [
        "get_thread",
        "get_threads",
        "get_friend_requests",
        "get_person",
        "get_people",
        "get_fees",
      ],
      // Change methods can modify the state, but you don't receive the returned value when called
      changeMethods: [
        "add_post",
        "react_to_post",
        "unreact_to_post",
        "add_thread",
        "send_friend_request",
        "accept_friend_request",
        "reject_friend_request",
        "put_person",
      ],
      // Sender is the account ID tos initialize transactions.
      // getAccountId() will return empty string if user is still unauthorized
      sender: walletConnection.getAccountId(),
    }
  );

  return { contract, currentUser, nearConfig, walletConnection };
}

async function connect(nearConfig) {
  // Connects to NEAR and provides `near`, `walletAccount` and `contract` objects in `window` scope
  // Initializing connection to the NEAR node.
  window.near = await nearAPI.connect({
    deps: {
      keyStore: new nearAPI.keyStores.BrowserLocalStorageKeyStore(),
    },
    ...nearConfig,
  });

  // Needed to access wallet login
  window.walletConnection = new nearAPI.WalletConnection(window.near);

  // Initializing our contract APIs by contract name and configuration.
  window.contract = await new nearAPI.Contract(
    window.walletConnection.account(),
    nearConfig.contractName,
    {
      sender: window.walletConnection.getAccountId(),
    }
  );
}

function updateUI() {
  if (!window.walletConnection.getAccountId()) {
    Array.from(document.querySelectorAll(".sign-in")).map(
      (it) => (it.style = "display: block;")
    );
  } else {
    Array.from(document.querySelectorAll(".after-sign-in")).map(
      (it) => (it.style = "display: block;")
    );
    initContract().then(async (dapp) => {
      const app = Elm.Main.init({
        node: document.getElementById("root"),
        flags: dapp.currentUser.accountId,
      });

      app.ports.addThread.subscribe(async (name) => {
        console.log("thread name", name);
        const { thread_fee } = await dapp.contract.get_fees();
        const res = await dapp.contract.add_thread(
          {
            thread_name: name,
          },
          GAS_FEE,
          thread_fee
        );

        app.ports.gotThreadCreated.send(res);
      });

      app.ports.getThreads.subscribe(async () => {
        const getRes = await dapp.contract.get_threads({
          from_index: 0,
          limit: 100,
        });
        app.ports.gotThreads.send(getRes);
      });

      app.ports.getPerson.subscribe(async (account) => {
        const getRes = await dapp.contract.get_person({
          account,
        });
        console.log(getRes);
        app.ports.gotPerson.send(getRes);
      });

      app.ports.putPerson.subscribe(async (args) => {
        const getRes = await dapp.contract.put_person(args);
        app.ports.gotPerson.send(getRes);
      });

      app.ports.acceptRequest.subscribe(async (from_account) => {
        const { friend_fee } = await dapp.contract.get_fees();
        await dapp.contract.accept_friend_request(
          { from_account },
          GAS_FEE,
          friend_fee
        );
        app.ports.requestAccepted.send("");
      });

      app.ports.rejectRequest.subscribe(async (from_account) => {
        await dapp.contract.reject_friend_request({ from_account });
        app.ports.requestRejected.send("");
      });

      app.ports.sendRequest.subscribe(async (args) => {
        const { friend_fee } = await dapp.contract.get_fees();
        await dapp.contract.send_friend_request(args, GAS_FEE, friend_fee);
        app.ports.requestSent.send("");
      });

      app.ports.getPeople.subscribe(async () => {
        const getRes = await dapp.contract.get_people({
          from_index: 0,
          limit: 100,
        });
        app.ports.gotPeople.send(getRes);
      });

      app.ports.getRequests.subscribe(async (account) => {
        const getRes = await dapp.contract.get_friend_requests({
          account,
          from_index: 0,
          limit: 100,
        });
        app.ports.gotRequests.send(getRes);
      });

      app.ports.getThread.subscribe(async (threadName) => {
        console.log(threadName);
        const getRes = await dapp.contract.get_thread({
          thread_name: threadName,
          from_index: 0,
          limit: 100,
        });
        console.log(getRes);
        app.ports.gotThread.send(getRes);
      });

      app.ports.reactToPost.subscribe(
        async ({ threadName: thread_name, postId }) => {
          await dapp.contract.react_to_post({
            thread_name,
            post_id: postId,
            reaction: "Like",
          });
          const getRes = await dapp.contract.get_thread({
            thread_name,
            from_index: 0,
            limit: 100,
          });
          app.ports.gotThread.send(getRes);
        }
      );

      app.ports.unreactToPost.subscribe(
        async ({ threadName: thread_name, postId }) => {
          await dapp.contract.unreact_to_post({
            thread_name,
            post_id: postId,
          });

          const getRes = await dapp.contract.get_thread({
            thread_name,
            from_index: 0,
            limit: 100,
          });
          app.ports.gotThread.send(getRes);
        }
      );

      app.ports.addPost.subscribe(
        async ({ threadName: thread_name, text, cid }) => {
          const { post_fee } = await dapp.contract.get_fees();
          await dapp.contract.add_post(
            {
              thread_name,
              text: text,
              cid: cid,
            },
            GAS_FEE,
            post_fee
          );
          const getRes = await dapp.contract.get_thread({
            thread_name,
            from_index: 0,
            limit: 100,
          });

          console.log(getRes);
          app.ports.gotThread.send(getRes);
        }
      );
    });
  }
}

// Log in user using NEAR Wallet on "Sign In" button click
document.querySelector(".sign-in .btn").addEventListener("click", () => {
  walletConnection.requestSignIn(
    nearConfig.contractName,
    "Rust Counter Example"
  );
});

window.nearInitPromise = connect(nearConfig)
  .then(updateUI)
  .catch(console.error);
