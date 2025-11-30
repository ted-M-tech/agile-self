'use client';

import { ArrowRight, Brain, TrendingUp, Target, Shield, Sparkles, CheckCircle2, Zap } from 'lucide-react';
import { Button } from './ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';
import { motion } from 'framer-motion';

interface LandingPageProps {
  onGetStarted: () => void;
}

export function LandingPage({ onGetStarted }: LandingPageProps) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-600 via-indigo-600 to-purple-700">
      {/* Hero Section */}
      <div className="relative overflow-hidden">
        <div className="absolute inset-0 bg-grid-white/[0.05] bg-[size:60px_60px]" />
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 sm:py-32">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center space-y-8"
          >
            <Badge className="bg-white/20 text-white border-white/30 backdrop-blur-sm px-4 py-2">
              <Sparkles className="w-4 h-4 mr-2" />
              Your AI Growth Partner
            </Badge>

            <h1 className="text-white text-5xl sm:text-6xl lg:text-7xl max-w-4xl mx-auto leading-tight font-bold">
              Agile Self
            </h1>

            <p className="text-xl sm:text-2xl text-blue-100 max-w-2xl mx-auto">
              Turn Reflection Into Action
            </p>

            <p className="text-lg text-blue-200 max-w-3xl mx-auto leading-relaxed">
              A powerful self-retrospective tool that adapts agile methodologies for personal growth.
              Track your wellbeing, identify patterns with AI, and build actionable habits.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 justify-center pt-4">
              <Button
                size="lg"
                onClick={onGetStarted}
                className="bg-white text-blue-600 hover:bg-blue-50 px-8 py-6 text-lg"
              >
                Get Started Free
                <ArrowRight className="w-5 h-5 ml-2" />
              </Button>
            </div>
          </motion.div>
        </div>
      </div>

      {/* Features Section */}
      <div className="bg-white py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold text-slate-900 mb-4">Powerful Features for Personal Growth</h2>
            <p className="text-slate-600 text-lg max-w-2xl mx-auto">
              Everything you need to build a consistent reflection habit and achieve continuous self-improvement
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
              viewport={{ once: true }}
            >
              <Card className="h-full border-2 hover:border-blue-300 transition-all hover:shadow-lg">
                <CardHeader>
                  <div className="w-12 h-12 rounded-full bg-blue-100 flex items-center justify-center mb-4">
                    <Brain className="w-6 h-6 text-blue-600" />
                  </div>
                  <CardTitle>AI-Powered Insights</CardTitle>
                  <CardDescription>
                    Advanced sentiment analysis and pattern recognition to help you understand your growth journey
                  </CardDescription>
                </CardHeader>
              </Card>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.2 }}
              viewport={{ once: true }}
            >
              <Card className="h-full border-2 hover:border-purple-300 transition-all hover:shadow-lg">
                <CardHeader>
                  <div className="w-12 h-12 rounded-full bg-purple-100 flex items-center justify-center mb-4">
                    <TrendingUp className="w-6 h-6 text-purple-600" />
                  </div>
                  <CardTitle>Wellbeing Score</CardTitle>
                  <CardDescription>
                    Track your emotional wellbeing over time with intelligent scoring based on your reflections
                  </CardDescription>
                </CardHeader>
              </Card>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.3 }}
              viewport={{ once: true }}
            >
              <Card className="h-full border-2 hover:border-green-300 transition-all hover:shadow-lg">
                <CardHeader>
                  <div className="w-12 h-12 rounded-full bg-green-100 flex items-center justify-center mb-4">
                    <Target className="w-6 h-6 text-green-600" />
                  </div>
                  <CardTitle>KPTA Framework</CardTitle>
                  <CardDescription>
                    Keep, Problem, Try, Action - A proven methodology adapted from agile practices
                  </CardDescription>
                </CardHeader>
              </Card>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.4 }}
              viewport={{ once: true }}
            >
              <Card className="h-full border-2 hover:border-indigo-300 transition-all hover:shadow-lg">
                <CardHeader>
                  <div className="w-12 h-12 rounded-full bg-indigo-100 flex items-center justify-center mb-4">
                    <CheckCircle2 className="w-6 h-6 text-indigo-600" />
                  </div>
                  <CardTitle>Action Tracking</CardTitle>
                  <CardDescription>
                    Convert insights into concrete actions and track completion to drive real change
                  </CardDescription>
                </CardHeader>
              </Card>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.5 }}
              viewport={{ once: true }}
            >
              <Card className="h-full border-2 hover:border-orange-300 transition-all hover:shadow-lg">
                <CardHeader>
                  <div className="w-12 h-12 rounded-full bg-orange-100 flex items-center justify-center mb-4">
                    <Zap className="w-6 h-6 text-orange-600" />
                  </div>
                  <CardTitle>Smart Reminders</CardTitle>
                  <CardDescription>
                    Gentle, customizable notifications to build and maintain your reflection habit
                  </CardDescription>
                </CardHeader>
              </Card>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.6 }}
              viewport={{ once: true }}
            >
              <Card className="h-full border-2 hover:border-slate-300 transition-all hover:shadow-lg">
                <CardHeader>
                  <div className="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center mb-4">
                    <Shield className="w-6 h-6 text-slate-600" />
                  </div>
                  <CardTitle>Privacy First</CardTitle>
                  <CardDescription>
                    Your data stays private and secure. Local storage with optional cloud sync
                  </CardDescription>
                </CardHeader>
              </Card>
            </motion.div>
          </div>
        </div>
      </div>

      {/* How It Works */}
      <div className="bg-gradient-to-br from-slate-50 to-blue-50 py-20">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold text-slate-900 mb-4">How It Works</h2>
            <p className="text-slate-600 text-lg">Simple, effective, transformative</p>
          </div>

          <div className="space-y-12">
            {[
              {
                step: '1',
                title: 'Reflect Weekly or Monthly',
                description: 'Use the KPTA framework to capture what went well (Keep), challenges you faced (Problem), new approaches to try (Try), and concrete next steps (Action).',
                color: 'bg-blue-500',
              },
              {
                step: '2',
                title: 'Get AI Insights',
                description: 'Our AI analyzes your entries to detect patterns, track sentiment, and calculate your wellbeing score over time.',
                color: 'bg-purple-500',
              },
              {
                step: '3',
                title: 'Take Action & Grow',
                description: 'Track your action items, review insights, and watch your wellbeing score improve as you build better habits.',
                color: 'bg-green-500',
              },
            ].map((item, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, x: -20 }}
                whileInView={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.5, delay: index * 0.2 }}
                viewport={{ once: true }}
                className="flex gap-6 items-start"
              >
                <div className={`${item.color} text-white rounded-full w-12 h-12 flex items-center justify-center flex-shrink-0 font-bold text-xl`}>
                  {item.step}
                </div>
                <div>
                  <h3 className="text-xl font-semibold text-slate-900 mb-2">{item.title}</h3>
                  <p className="text-slate-600 leading-relaxed">{item.description}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>

      {/* CTA Section */}
      <div className="bg-gradient-to-br from-blue-600 to-indigo-600 py-20">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            viewport={{ once: true }}
            className="space-y-8"
          >
            <h2 className="text-white text-4xl sm:text-5xl font-bold">
              Start Your Growth Journey Today
            </h2>
            <p className="text-blue-100 text-lg max-w-2xl mx-auto">
              Join thousands who are turning reflection into action and building better habits with Agile Self.
            </p>
            <Button
              size="lg"
              onClick={onGetStarted}
              className="bg-white text-blue-600 hover:bg-blue-50 px-8 py-6 text-lg"
            >
              Get Started Free
              <ArrowRight className="w-5 h-5 ml-2" />
            </Button>
          </motion.div>
        </div>
      </div>

      {/* Footer */}
      <div className="bg-slate-900 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center space-y-4">
            <h3 className="text-white text-xl font-semibold">Agile Self</h3>
            <p className="text-slate-400">Turn Reflection Into Action</p>
            <p className="text-slate-500 text-sm">© 2025 Agile Self. Built with care for your growth.</p>
          </div>
        </div>
      </div>
    </div>
  );
}
