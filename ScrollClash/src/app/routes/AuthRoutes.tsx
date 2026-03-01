import React from 'react';
import { BrainCustomizationProvider } from '../../features/brainLab/context/BrainCustomizationContext';
import LoginScreen from '../screens/Login';
import LoadingScreen from '../screens/Loading';

export function LoginWrapper() {
  return (
    <BrainCustomizationProvider>
      <LoginScreen />
    </BrainCustomizationProvider>
  );
}

export function LoadingWrapper() {
  return (
    <BrainCustomizationProvider>
      <LoadingScreen />
    </BrainCustomizationProvider>
  );
}
