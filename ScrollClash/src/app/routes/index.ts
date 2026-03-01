import { createHashRouter } from "react-router";
import Root from "../Root";
import HomeScreen from "../../features/home/HomeScreen";
import LeaderboardScreen from "../../features/leaderboard/LeaderboardScreen";
import GraveyardScreen from "../screens/Graveyard";
import ProfileScreen from "../screens/Profile";
import PreDuel from "../screens/PreDuel";
import DuelArenaScreen from "../screens/DuelArena";
import DuelResultScreen from "../screens/DuelResult";
import BrainLabScreen from "../screens/BrainLab";
import BoostInventory from "../screens/BoostInventory";
import { LoginWrapper, LoadingWrapper } from "./AuthRoutes";
import { ROUTES } from "./routeConfig";

export const router = createHashRouter([
  {
    path: "/login",
    Component: LoginWrapper,
  },
  {
    path: "/loading",
    Component: LoadingWrapper,
  },
  {
    path: ROUTES.HOME,
    Component: Root,
    children: [
      { index: true, Component: HomeScreen },
      { path: "leaderboard", Component: LeaderboardScreen },
      { path: "graveyard", Component: GraveyardScreen },
      { path: "profile", Component: ProfileScreen },
      { path: "duel", Component: PreDuel },
      { path: "duel/arena", Component: DuelArenaScreen },
      { path: "duel/result", Component: DuelResultScreen },
      { path: "brain-lab", Component: BrainLabScreen },
      { path: "boosts", Component: BoostInventory },
    ],
  },
]);